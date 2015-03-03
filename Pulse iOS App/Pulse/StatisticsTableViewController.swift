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
    @IBOutlet weak var ageMaxHRLabel: UILabel!
    
    //1
    @IBOutlet weak var heartRateGraph: BEMSimpleLineGraphView!
    @IBOutlet weak var avgHeartRateLabel: UILabel!
    
    //2
    @IBOutlet weak var spO2Graph: BEMSimpleLineGraphView!
    
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
        
        if HKHealthStore.isHealthDataAvailable() {
            
            healthStore?.requestAuthorizationToShareTypes(writeDataTypes, readTypes: readDataTypes) { (success, error) in
                
                if !success {
                    println("ERROR: Failed to get access to HealthStore read write data types: \(error.localizedDescription)")
                }
            }
        }
        
        //0
        ageMaxHRLabel.designatedBond.bind(statisticsManager.ageMaxHR)
        
        //1
        hrGraphDelegate.graphView = heartRateGraph
        hrGraphDelegate.designatedBond.bind(statisticsManager.hrData)
        heartRateGraph.backgroundColor = UIColor(red:31.0/255.0, green:187.0/255.0, blue:166.0/255.0, alpha:1.0)
        
        //2
        spGraphDelegate.graphView = spO2Graph
        spGraphDelegate.designatedBond.bind(statisticsManager.hrData)
        spO2Graph.backgroundColor = UIColor(red:0.0, green:140.0/255.0, blue:255.0/255.0, alpha:1.0)
        
        statisticsManager.refreshAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
