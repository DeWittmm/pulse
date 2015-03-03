//
//  StatisticsTableViewController.swift
//  Pulse
//
//  Created by Michael DeWitt on 1/21/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit
import HealthKit

class StatisticsTableViewController: UITableViewController, HKAccessProtocol {
    
    struct MainStoryboard {
        struct ViewControllerIdentifiers {
        }
        
        struct TableViewCellIdentifiers {
            static let basicCell = "BasicCell"
            static let userCell = "UserCell"
            static let graphCell = "GraphCell"
        }
    }
    
    //MARK: - Outlets
    
    //MARK: - Properties
    var statisticsManager: StatisticsInfoManager!
    var hrGraphDelegate = GraphDelegate()
    var spGraphDelegate = GraphDelegate()
    
    var bonds = [Bond<String?>]()
    
    var healthStore: HKHealthStore? {
        didSet {
            self.statisticsManager = StatisticsInfoManager(healthStore: self.healthStore!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//         self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if HKHealthStore.isHealthDataAvailable() {
            
            healthStore?.requestAuthorizationToShareTypes(writeDataTypes, readTypes: readDataTypes) { (success, error) in
                
                if !success {
                    println("ERROR: Failed to get access to HealthStore read write data types: \(error.localizedDescription)")
                }
                self.statisticsManager.updateValues()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return 2
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier: String
        
        var cell: UITableViewCell
        switch (indexPath.section, indexPath.row) {
        case (0, _):
            let identifier = MainStoryboard.TableViewCellIdentifiers.userCell
            cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! UITableViewCell
        
            let ageLableBond = Bond() { [unowned self] txt in
                cell.textLabel?.text = txt
            }
            ageLableBond.bind(statisticsManager.userAge)
            bonds.append(ageLableBond)
            
//            cell.detailTextLabel?.designatedBond.bind(statisticsManager.ageMaxHR)
        case (_, 0):
            let identifier = MainStoryboard.TableViewCellIdentifiers.graphCell
            let graphCell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! GraphTableViewCell
            
            if indexPath.section % 2 == 0 {
                spGraphDelegate.graphView = graphCell.graph
                graphCell.graph.backgroundColor = UIColor(red:0.0, green:140.0/255.0, blue:255.0/255.0, alpha:1.0)
            }
            else {
                hrGraphDelegate.graphView = graphCell.graph
                graphCell.graph.backgroundColor = UIColor(red:31.0/255.0, green:187.0/255.0, blue:166.0/255.0, alpha:1.0)
            }
            
            cell = graphCell
        default:
            let identifier = MainStoryboard.TableViewCellIdentifiers.basicCell
            cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! UITableViewCell
            
            cell.textLabel?.text = "Basic Info"
            cell.detailTextLabel?.text = "---"
        }
        
        return cell
    }
    
    //MARK: - TableView Accessory Views
    override func tableView(tableView: UITableView,
        titleForHeaderInSection section: Int) -> String? {
            switch section {
            case 0:
                return "User Info"
            case 1:
                return "Heart Rate"
            case 2:
                return "Blood Oxygen Levels"
            default:
                return ""
            }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 55
        }
        
        if indexPath.row == 0 {
            return 250
        }
        return 55
    }
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
}
