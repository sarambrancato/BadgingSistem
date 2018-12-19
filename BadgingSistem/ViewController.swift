//
//  ViewController.swift
//  BadgingSistem
//
//  Created by Sara Brancato on 19/12/18.
//  Copyright © 2018 Sara Brancato. All rights reserved.
//

import UIKit
import CoreData

enum Status: Int16 {
    case In = 0
    case Out = 1
}


class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    

    @IBOutlet weak var hoursTableView: UITableView!
    @IBOutlet weak var cohort: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var badgeButton: UIButton!
    
    var todayTimes: [NSManagedObject] = []
    var badgingTimes: [NSManagedObject] = []

    
    var inOut: Bool = false
    
    let clock = Clock()
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hoursTableView.delegate = self
        hoursTableView.dataSource = self
        // Get the current calendar with local time zone
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "BadgingTime")
        // Get today's beginning & end
        let dateFrom = calendar.startOfDay(for: Date()) // eg. 2016-10-10 00:00:00
        let dateTo = calendar.date(byAdding: .day, value: 1, to: dateFrom)
        // Note: Times are printed in UTC. Depending on where you live it won't print 00:00:00 but it will work with UTC times which can be converted to local time
        
        // Set predicate as date being today's date
        let fromPredicate = NSPredicate(format: "hour >= %@", dateFrom as NSDate)
        let toPredicate = NSPredicate(format: "hour < %@", dateTo! as NSDate)
        let datePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fromPredicate, toPredicate])
        fetchRequest.predicate = datePredicate
        
       
        do {
            todayTimes = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        let fetchRequest2 =
            NSFetchRequest<NSManagedObject>(entityName: "BadgingTime")
        do {
            badgingTimes = try managedContext.fetch(fetchRequest2)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                     selector: #selector(ViewController.updateTimeLabel), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTimeLabel()
    }
    
    @objc func updateTimeLabel() {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        timeLabel.text = formatter.string(from: clock.currentTime as Date)
    }
    @IBAction func badgeInOut(_ sender: Any) {
        
        
        if(inOut){
            self.save(hour: self.clock.currentTime, type: Status.Out.rawValue)
            
            badgeButton.setTitle("Badge In", for: .normal)
            inOut = false
        }
        else {
            self.save(hour: self.clock.currentTime, type: Status.In.rawValue)
            
            badgeButton.setTitle("Badge Out", for: .normal)
            inOut = true
        }
        hoursTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todayTimes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: "Cell",
                                          for: indexPath)
        let badgedTime = todayTimes[indexPath.row]
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        cell.textLabel?.text = formatter.string(from: badgedTime.value(forKeyPath: "hour") as! Date)
        if(badgedTime.value(forKeyPath: "type") as! Int16 == Status.In.rawValue) {
            cell.detailTextLabel?.text = "In"
        } else{
            cell.detailTextLabel?.text = "Out"
        }
        return cell
    }
    
    deinit {
        if let timer = self.timer {
            timer.invalidate()
        }
    }
    
    func save(hour: Date, type: Int16) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "BadgingTime",
                                       in: managedContext)!
        let badgeTime = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        badgeTime.setValue(hour, forKeyPath: "hour")
        badgeTime.setValue(type, forKeyPath: "type")
        // 4
        do {
            try managedContext.save()
            todayTimes.append(badgeTime)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}



