//
//  AllNotesVC.swift
//  LumpNotes
//
//  Created by vibin joby on 2020-01-19.
//  Copyright © 2020 vibin joby. All rights reserved.
//

import UIKit

class AllNotesVC: UIViewController, UITableViewDelegate, UITableViewDataSource,AddEditNoteDelegate,UITextFieldDelegate {
    
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var emptyContainerView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var addNotesBtn: UIButton!
    @IBOutlet weak var notesTableView: UITableView!
    @IBOutlet weak var NotesNotFoundVC: UIView!
    @IBOutlet weak var sortBtn: UIButton!
    @IBOutlet weak var categoryNameLbl: UILabel!
    var categories:[String]?
    var isAscendingSort = false
    var categoryName:String?
    var selectedNoteForUpdate:Notes?
    let utils = Utilities()
    var notes = [Notes]()
    var filteredNotes = [Notes]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Utilities().deleteAllRecordings()
        notes = DataModel().fetchNotesForCategory(categoryName!)
        filteredNotes = notes
        applyPresetConstraints()
        if let category = categoryName {
            categoryNameLbl.text = "\(category) Notes"
        }
    }
    
    func applyPresetConstraints() {
        addNotesBtn.layer.cornerRadius = addNotesBtn.frame.size.width/2
        addNotesBtn.layer.masksToBounds = true
        topView.layer.cornerRadius = 20
        view.backgroundColor = utils.hexStringToUIColor(hex: "#F7F7F7")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if notes.count > 0 {
            if filteredNotes.count < 1 {
                emptyContainerView.isHidden = false
            } else {
                emptyContainerView.isHidden = true
                NotesNotFoundVC.isHidden = true
            }
        } else {
            NotesNotFoundVC.isHidden = true
            emptyContainerView.isHidden = false
        }
        return filteredNotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notesCell") as! NotesCell
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let note_created_timestamp = filteredNotes[indexPath.row].note_created_timestamp {
            let myDate = formatter.date(from: note_created_timestamp)
            formatter.dateFormat = "dd-MMM-yyyy"
            let date = formatter.string(from: myDate!)
            cell.dateLblTxt.text = date
            
            //For time
            formatter.timeStyle = .short
            let timeString = formatter.string(from: myDate!)
            cell.timeStampLblTxt.text = timeString
        }
        cell.noteTxt.text = filteredNotes[indexPath.row].note_title!
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "Delete",
          handler: { (action, view, completionHandler) in
          DataModel().deleteNote(self.categoryName!, self.notes[indexPath.row])
          self.notes.remove(at: indexPath.row)
          self.filteredNotes.remove(at: indexPath.row)
          self.notesTableView.deleteRows(at: [indexPath], with: .fade)
          completionHandler(true)
        })
        deleteAction.image = UIGraphicsImageRenderer(size: CGSize(width: 25, height: 25)).image { _ in
            UIImage(named: "trash")?.draw(in: CGRect(x: 0, y: 0, width: 25, height: 25))
        }
        deleteAction.backgroundColor = .red
        
        if categories!.count > 1 {
            let moveAction = UIContextualAction(style: .normal, title: "Move",
              handler: { (action, view, completionHandler) in
                let alertController = UIAlertController(title: "Move Notes", message: "Select a category for moving the note", preferredStyle: .actionSheet)

                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in}
                alertController.addAction(cancelAction)
                
                if let categoryArr = self.categories {
                    for category in categoryArr {
                        if !self.categoryName!.elementsEqual(category) {
                            let moveNote = UIAlertAction(title: category, style: .default) { (action) in
                                DataModel().moveNoteToCategory(self.categoryName!, self.notes[indexPath.row], category)
                                self.notes.remove(at: indexPath.row)
                                self.filteredNotes.remove(at: indexPath.row)
                                self.notesTableView.deleteRows(at: [indexPath], with: .fade)
                            }
                            alertController.addAction(moveNote)
                        }
                    }
                }
                self.present(alertController, animated: true) {}
              completionHandler(true)
            })
            moveAction.image = UIGraphicsImageRenderer(size: CGSize(width: 25, height: 25)).image { _ in
                UIImage(named: "move")?.draw(in: CGRect(x: 0, y: 0, width: 25, height: 25))
            }
            moveAction.backgroundColor = .blue
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction,moveAction])
            return configuration
        } else {
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedNoteForUpdate = filteredNotes[indexPath.row]
        performSegue(withIdentifier: "ShowNotes", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: - Text field Delegate functions
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        var isFound = false
        if searchBar.text != nil && !searchBar.text!.isEmpty {
            filteredNotes = []
            for notesObj in notes {
                if notesObj.note_title!.lowercased().contains(searchBar!.text!.lowercased()) {
                    filteredNotes.append(notesObj)
                    isFound = true
                }
            }
            if isFound {
                notesTableView.reloadData()
            } else {
                NotesNotFoundVC.isHidden = false
            }
            
        } else {
            filteredNotes = notes
            notesTableView.reloadData()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      textField.resignFirstResponder()
      return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowNotes" {
            let segueDest = segue.destination as! AddEditNoteVC
            segueDest.categoryName = categoryName
            segueDest.delegate = self
            segueDest.isEditNote = true
            segueDest.notesObj = selectedNoteForUpdate
        } else if segue.identifier == "addNewNote" {
            let segueDest = segue.destination as! AddEditNoteVC
            segueDest.categoryName = categoryName
            segueDest.delegate = self
        }
    }
    
    @IBAction func onSortBtnClick(_ sender: UIButton) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if isAscendingSort {
            filteredNotes.sort(){dateFormatter.date(from:$0.note_created_timestamp!)! >  dateFormatter.date(from:$1.note_created_timestamp!)!}
            isAscendingSort = false
        } else {
            filteredNotes.sort(){dateFormatter.date(from:$0.note_created_timestamp!)! <  dateFormatter.date(from:$1.note_created_timestamp!)!}
            isAscendingSort = true
        }
        notesTableView.reloadData()
    }
    
    @IBAction func onCreateNewNote(_ sender: UIButton) {
        performSegue(withIdentifier: "addNewNote", sender: nil)
    }
    
    func reloadTableAtLastIndex() {
        notes = DataModel().fetchNotesForCategory(categoryName!)
        filteredNotes = notes
        notesTableView.reloadData()
    }
}
