//
//  LearnViewController.swift
//  Amsel
//
//  Created by Anja on 01.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class LearnViewController: GradientViewController, UITableViewDelegate, UITableViewDataSource {
    
    let lessons = loadLessons()
    
    @IBOutlet var learningProgress: UIProgressView!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var absoluteSectionCount = 0
        for lesson in lessons {
            for _ in lesson.sections {
                absoluteSectionCount += 1
            }
        }
        learningProgress.progress = Float(userPassedSectionCount()) / Float(absoluteSectionCount)
    }
    
    // Prepare the data of segue destination view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If triggered seque is the "showLesson" seque
        switch segue.identifier {
        case "showLesson":
            // Figure out which row was just tapped
            if let indexPath = tableView.indexPathForSelectedRow {
                
                // Get the item associated with this row and pass it along
                let lesson = lessons[indexPath.row]
                let lessonViewController = segue.destination as! LessonViewController
                lessonViewController.sections = lesson.sections
            }
        default:
            preconditionFailure("Unexpected segue identifier.")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonCell", for: indexPath) as! LessonCell
        
        cell.titleLabel.text = lessons[indexPath.row].title
        
        return cell
    }
    
}
