//
//  LessonViewController.swift
//  Amsel
//
//  Created by Anja on 02.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class LessonViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var previousPageButton: UIButton!
    @IBOutlet var nextPageButton: UIButton!
    
    @IBOutlet var pageTitleLabel: UILabel!
    @IBOutlet var pageNumberLabel: UILabel!
    
    @IBOutlet var lessonTextView: UITextView!
    @IBOutlet var codeBlockCellView: UICollectionView!
    @IBOutlet var multipleChoiceTableView: MultipleChoiceTable!
    @IBOutlet var feedbackTextView: UITextView!
    
    let codeBlockLayout = CodeBlockFlowLayout(
        minimumInteritemSpacing: 0,
        minimumLineSpacing: 0,
        sectionInset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    )
    
    
    var currentSection: Int = 0 {
        didSet {
            currentStatus = .initial
        }
    }
    var currentStatus: SectionStatus = .initial {
        didSet {
            switch currentStatus {
            case .initial:
                sectionInitial()
            case .passed:
                if oldValue != currentStatus {
                    sectionPassed()
                }
            case .failed:
                sectionFailed()
            }
        }
    }
    var currentCodeBlock: [[CodeBlock]]?
    var sections: [Section]!
    
    enum SectionStatus {
        case initial
        case failed
        case passed
    }
    
    override func viewDidLoad() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        
        currentSection = 0
        
        codeBlockCellView.collectionViewLayout = codeBlockLayout
        codeBlockCellView.contentInsetAdjustmentBehavior = .always
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AmselLesson.shared.stopAll()
    }
    
    @IBAction func closeLesson(_ sender: UIButton) {
        AmselLesson.shared.stopAll()
        dismiss(animated: true, completion: nil)
    }
    @IBAction func previousPage(_ sender: UIButton) {
        AmselLesson.shared.stopAll()
        currentSection = min(max(currentSection - 1, 0), sections.count-1)
    }
    @IBAction func nextPage(_ sender: UIButton) {
        AmselLesson.shared.stopAll()
        
        // Save old status -> if old status was failed, the user has pressed on the "check" button -> no page change
        let oldStatus = currentStatus
        checkUserInput()
        
        // Last page is passed -> quit lesson
        // every other page is passed -> go to next section
        if currentStatus == .passed && oldStatus == .passed && (currentSection + 1) == sections.count {
            closeLesson(sender)
        } else if currentStatus == .passed && oldStatus == .passed {
            currentSection = min(max(currentSection + 1, 0), sections.count-1)
        }
    }
    
    func sectionInitial() {
        // Pre-process data
        currentCodeBlock = sections[currentSection].getSectionedCodeBlock()
        // Setup labels
        pageTitleLabel.text = sections[currentSection].title
        pageNumberLabel.text = "\(currentSection + 1) / \(sections.count)"
        
        // Reload lesson data
        feedbackTextView.attributedText = nil
        lessonTextView.attributedText = sections[currentSection].task.htmlToAttributedString
        codeBlockCellView.reloadData()
        multipleChoiceTableView.reloadData()
        
        // Check user sucess and set buttons accordingly
        if didUserPassSection(withId: sections[currentSection].id) {
            currentStatus = .passed
        } else {
            nextPageButton.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        }
        previousPageButton.isHidden = (currentSection == 0) // Hide left button on first page
    }
    
    func sectionPassed() {
        userPassedSection(withId: sections[currentSection].id)
        fillSolution()
        if let feedbackPassed = sections[currentSection].feedbackPassed {
            feedbackTextView.attributedText = feedbackPassed.htmlToAttributedString
        }
        nextPageButton.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        codeBlockCellView.reloadData()
    }
    func sectionFailed() {
        userFailedSection(withId: sections[currentSection].id)
        if let feedbackFailed = sections[currentSection].feedbackFailed {
            feedbackTextView.attributedText = feedbackFailed.htmlToAttributedString
        }
        nextPageButton.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        codeBlockCellView.reloadData()
    }
    
    func checkUserInput() {
        var inputValid = true
        // Check code blocks
        for sectionIdx in 0...max(self.numberOfSections(in: codeBlockCellView) - 1, 0) {
            for rowIdx in 0...max(self.collectionView(codeBlockCellView, numberOfItemsInSection: sectionIdx) - 1, 0)
            {
                if let cell = codeBlockCellView.cellForItem(at: IndexPath(row: rowIdx, section: sectionIdx)),
                    cell.reuseIdentifier == "CodeBlockGap" {
                    
                    let gapCell = cell as! CodeBlockGapCell
                    if !gapCell.passed() {
                        inputValid = false
                    }
                }

            }
        }
        // Check multiple choice
        if let multipleChoice = sections[currentSection].multipleChoice {
            for (index, choice) in multipleChoice.enumerated() {
                let indexPath = IndexPath(row: index, section: 0)
                if let choiceCell = multipleChoiceTableView.cellForRow(at: indexPath),
                    choice.solution == choiceCell.isSelected {
                    // user input is valid
                } else {
                    inputValid = false
                }
            }
        }
        if inputValid {
            currentStatus = .passed
        } else {
            currentStatus = .failed
        }
    }
    
    func fillSolution() {
        if let multipleChoice = sections[currentSection].multipleChoice {
            for (index, choice) in multipleChoice.enumerated() {
                let indexPath = IndexPath(row: index, section: 0)
                if choice.solution {
                    multipleChoiceTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
                } else {
                    multipleChoiceTableView.deselectRow(at: indexPath, animated: true)
                }
            }
        }
        if let amselAction = sections[currentSection].amselAction {
            switch amselAction.type {
            case .print:
                AmselLesson.shared.amselPrint(amselAction.parameter[0])
            case .forward:
                if let seconds = Int(amselAction.parameter[0]) {
                    AmselLesson.shared.driveStraight(seconds: seconds)
                }
            case .forwardTillBarrier:
                AmselLesson.shared.driveTillBarrier()
            case .left:
                if let seconds = Int(amselAction.parameter[0]) {
                    AmselLesson.shared.driveCircle(seconds: seconds, direction: .left)
                }
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        codeBlockLayout.outputSections.removeAll()
        return currentCodeBlock?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentCodeBlock?[section].count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let codeBlocks = currentCodeBlock {
            let codeBlock = codeBlocks[indexPath.section][indexPath.row]
            
            switch codeBlock.type {
            case .code:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CodeBlockCode", for: indexPath) as! CodeBlockCodeCell
                cell.codeLabel.text = codeBlock.content
                return cell
            case .gap:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CodeBlockGap", for: indexPath) as! CodeBlockGapCell
                cell.gapTextField.borderStyle = UITextField.BorderStyle.roundedRect
                cell.solution = codeBlock.content
                if currentStatus == .passed {
                    cell.gapTextField.text = codeBlock.content
                } else if currentStatus == .initial {
                    cell.gapTextField.text = ""
                }
                return cell
            case .output:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CodeBlockOutput", for: indexPath) as! CodeBlockOutputCell
                if currentStatus == .passed {
                    cell.outputLabel.text = "‣ " + codeBlock.content
                    codeBlockLayout.outputSections.append(indexPath.section)
                } else {
                    cell.outputLabel.text = " "
                }
                return cell
            }
        } else {
            // should never happen
            print("Error: CodeBlock cell creation - Section count or array size might be wrong")
            return UICollectionViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[currentSection].multipleChoice?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MultipleChoiceCell", for: indexPath) as! MultipleChoiceCell
        
        if let multipleChoices = sections[currentSection].multipleChoice {
            // Content
            cell.optionLetter.text = getListLetter(forIndex: indexPath.row)
            cell.optionText.text = multipleChoices[indexPath.row].title
            // Style
            cell.borderView.layer.borderColor = UIColor(named: "Text: Black")!.cgColor
            cell.borderView.layer.borderWidth = 1.0
        } else {
            // should never happen
            print("Error: MultipleChoice cell creation - Section count or array size might be wrong")
        }
        
        return cell
    }
    
    func getListLetter(forIndex index: Int) -> String {
        
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var letter = "-"
        
        if  0 <= index, index < alphabet.count {
            letter = String(alphabet[index])
        }
        
        return letter
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}
