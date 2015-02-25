//
//  StatisticsTableViewController.swift
//  Pulse
//
//  Created by Michael DeWitt on 1/21/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit
import HealthKit

class StatisticsTableViewController: UITableViewController, HKAccessDelegate {
    
    struct MainStoryboard {
        struct ViewControllerIdentifiers {
        }
        
        struct TableViewCellIdentifiers {
            static let basicCell = "BasicCell"
            static let graphCell = "GraphCell"
        }
    }
    
    //MARK: - Outlets
    
    //MARK: - Properties
    var hrGraphDelegate = GraphDelegate()
    var spGraphDelegate = GraphDelegate()
    
    var healthStore: HKHealthStore? {
        didSet {
            println("Did set HK!")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//         self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        healthStore?.requestAccess()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier: String
        
        var cell: UITableViewCell
        if indexPath.row == 0 {
            let identifier = MainStoryboard.TableViewCellIdentifiers.graphCell
            let graphCell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! GraphTableViewCell
            
            if indexPath.section % 2 == 0 {
                hrGraphDelegate.graphView = graphCell.graph
                graphCell.graph.backgroundColor = UIColor(red:0.0, green:140.0/255.0, blue:255.0/255.0, alpha:1.0)
            }
            else {
                spGraphDelegate.graphView = graphCell.graph
                graphCell.graph.backgroundColor = UIColor(red:31.0/255.0, green:187.0/255.0, blue:166.0/255.0, alpha:1.0)
            }
            
            cell = graphCell
        }
        else {
            let identifier = MainStoryboard.TableViewCellIdentifiers.basicCell
            cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! UITableViewCell
            
            cell.textLabel?.text = "Basic Info"
            cell.detailTextLabel?.text = "---"
        }
        
        return cell
    }
    
    //MARK: - TableView Accessory Views
    override func tableView(tableView: UITableView,
        titleForHeaderInSection section: Int) -> String?{
            return "Section \(section) Header"
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
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
