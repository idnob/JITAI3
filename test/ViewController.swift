//
//  ViewController.swift
//
//
//  Created by Andrea Bondi
//  Open. No rights Reserved.
//

import UIKit
import CoreMotion
import UserNotifications
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {
    
    @IBOutlet weak var gifView: UIImageView!
    let pedometer = CMPedometer() //define pedometer
    let pedometerRequest = CMPedometer() //pedometer for request
    var fromDate = NSDate(timeIntervalSinceNow: -1800)
    var counterRun = 0 // for debug purpose
    var intervalSitting  = 0 //count for how many intervals the subject has not been moving enough
    let exercises = ["mermaid", "triceps", "squat", "wooden-leg", "push-ups", "magic-carpet"] //possible exercises to show
    //to add stendup meetings and other Novo things
    var beginningDay = Date()
    var avgStepsLastWeek = 0 //average of steps done last working week (5 days) by the subject
    var distanceFromTarget = 0 //distance from target of 3000 steps during 8h working day
    var stepsThreshold = 0 //dynamic threshold that increases gradually day by day
    var fromLastWeek = NSDate(timeIntervalSinceNow: -3600*24*7) //starting to count from Monday last week
    var toLastWeek = NSDate(timeIntervalSinceNow: -3600*64) //finishing the count Friday last week
    var stepsWeek = [0,0,0,0,0]
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var starTaskButton: UIButton!
    @IBOutlet weak var stopTaskButton: UIButton!

   
    
    //check notification permission
    
    func initNotificationSetupCheck() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
            { (success, error) in
                if success {
                    print("Permission Granted")
                } else {
                    print("There was a problem with the notification permission!")
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    // end notification
    
    //end permission activity
    

    var timer = Timer()
    var backgroundTask = BackgroundTask()
    @IBAction func startBackgroundTask(_ sender: AnyObject) {
        
        beginningDay = Date() //save the moment the start button was pressed
        
        //for permission activity - in order to get permission for motion tasks at the beginning
        pedometerRequest.queryPedometerData(from: fromDate as Date, to: Date()) { (data2 : CMPedometerData!, error) -> Void in
            print("Steps done last 30 min: ",data2.numberOfSteps)
        }
        //end permission activity
        
        backgroundTask.startBackgroundTask()
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
        starTaskButton.alpha = 0.5
        starTaskButton.isUserInteractionEnabled = false
        
        stopTaskButton.alpha = 1
        stopTaskButton.isUserInteractionEnabled = true
        
        //***************** Check how much a user has walked last wekk and set the threshold *******************
//        var fromLastWeek = NSDate(timeIntervalSinceNow: -3600*24*7) //Monday at 8
//        toLastWeek = NSDate(timeIntervalSinceNow: -3600*160) //Monday at 16
//        if(CMPedometer.isStepCountingAvailable()){
//            pedometer.queryPedometerData(from: fromLastWeek as Date, to: toLastWeek as Date) { (data : CMPedometerData!, error) -> Void in
//                self.stepsWeek[0] = Int(data!.numberOfSteps)
//                print(self.stepsWeek[0])
//                print(self.fromLastWeek,self.toLastWeek)
//            }
//        }
//        print("culo")
//        fromLastWeek = NSDate(timeIntervalSinceNow: -3600*24*6) //Tuesday at 8
//        toLastWeek = NSDate(timeIntervalSinceNow: -3600*136) //Tuesday at 16
//        if(CMPedometer.isStepCountingAvailable()){
//            pedometer.queryPedometerData(from: fromLastWeek as Date, to: toLastWeek as Date) { (data : CMPedometerData!, error) -> Void in
//                self.stepsWeek[1] = Int(data!.numberOfSteps)
//                print(self.stepsWeek[0])
//                print(self.fromLastWeek,self.toLastWeek)
//            }
//        }
        
    }
    
    @IBAction func stopBackgroundTask(_ sender: AnyObject) {
        starTaskButton.alpha = 1
        starTaskButton.isUserInteractionEnabled = true
        stopTaskButton.alpha = 0.5
        stopTaskButton.isUserInteractionEnabled = false
        
        timer.invalidate()
        backgroundTask.stopBackgroundTask()
        
        //******************* when subject presses on stop I show the activity for the day **********************
   
      
        }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stopTaskButton.alpha = 0.5
        stopTaskButton.isUserInteractionEnabled = false
        initNotificationSetupCheck()
        gifView.loadGif(name: "giphy")
        
        }
    
  func timerAction() {
        
   
        counterRun+=1 // counter to see how many times the code is executed
        fromDate = NSDate(timeIntervalSinceNow: -1800) //30 min ago
        label.text = String(counterRun)
        
        let randomIndex = Int(arc4random_uniform(UInt32(exercises.count)))  // Get a random index
        let randomItem = exercises[randomIndex]     // Get a random item
        
        let imageURL = Bundle.main.url(forResource: randomItem, withExtension: "gif")
        let attachment = try! UNNotificationAttachment(identifier: randomItem , url: imageURL!, options: .none)
            
        if(CMPedometer.isStepCountingAvailable()){
            pedometer.queryPedometerData(from: fromDate as Date, to: Date()) { (data : CMPedometerData!, error) -> Void in
                print("Steps done last 30 min: ",data.numberOfSteps)
                print("fromDate",self.fromDate)
                print("Date()", Date())
                if data.numberOfSteps.decimalValue < 175 // research paper 375/h or 3000/8h; check test subjects avg
                {
                   self.intervalSitting += 1 //subject has been sedentary for the previous 30 min
                    switch self.intervalSitting{
                    case 1:
                        let notification = UNMutableNotificationContent()
                        notification.title = "Time to move!"
                        notification.subtitle = "Cannot walk?"
                        notification.body = "Do "+randomItem+" instead."
                        notification.attachments = [attachment]
                        
                        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
                        let request = UNNotificationRequest(identifier: "notification1", content: notification, trigger: notificationTrigger)
                        
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                        AudioServicesPlaySystemSound(SystemSoundID(1304))
                    case 2:
                        let notification = UNMutableNotificationContent()
                        notification.title = "Not much activity for 1h!"
                        notification.subtitle = "You health is important"
                        notification.body = "Consider going for a short walk"
                        notification.attachments = [attachment]
                        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
                        let request = UNNotificationRequest(identifier: "notification1", content: notification, trigger: notificationTrigger)
                        
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                        AudioServicesPlaySystemSound(SystemSoundID(1304))
                        
                    case 3:
                        let notification = UNMutableNotificationContent()
                        notification.title = "No much activity for 1,5h!"
                        notification.subtitle = "You health is important"
                        notification.body = "Your hearth is loosing health"
                        notification.attachments = [attachment]
                        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
                        let request = UNNotificationRequest(identifier: "notification1", content: notification, trigger: notificationTrigger)
                        
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                        AudioServicesPlaySystemSound(SystemSoundID(4095))
                        AudioServicesPlaySystemSound(SystemSoundID(1304))
                        AudioServicesPlaySystemSound(SystemSoundID(4095))
                    case 4:
                        let notification = UNMutableNotificationContent()
                        notification.title = "ALARM!"
                        notification.subtitle = "2 h of inactivity!"
                        notification.body = "Your are going go be healthier than 1min ago if you go for a walk"
                        notification.attachments = [attachment]
                        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
                        let request = UNNotificationRequest(identifier: "notification1", content: notification, trigger: notificationTrigger)
                        
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                        AudioServicesPlaySystemSound(SystemSoundID(4095))
                        AudioServicesPlaySystemSound(SystemSoundID(1304))
                        AudioServicesPlaySystemSound(SystemSoundID(4095))
                        AudioServicesPlaySystemSound(SystemSoundID(4095))
                        AudioServicesPlaySystemSound(SystemSoundID(1304))
                        AudioServicesPlaySystemSound(SystemSoundID(4095))
                        self.intervalSitting = 0
                        
                    default:
                        let notification = UNMutableNotificationContent()
                        notification.title = "Time to move!"
                        notification.subtitle = "Cannot walk?"
                        notification.body = "Do "+randomItem+" instead."
                        notification.attachments = [attachment]
                        
                        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
                        let request = UNNotificationRequest(identifier: "notification1", content: notification, trigger: notificationTrigger)
                        
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                        AudioServicesPlaySystemSound(SystemSoundID(1304))
                    }
                   
                } else {
                        self.intervalSitting = 0 // resetting the counter of sedentarity since the subject was active the last 30 min
                        print("Ciao Cipolla")
                        
                    
                        }
                
                DispatchQueue.main.async { () -> Void in
                    if(error == nil){
//                        self.dateLabel.text = "\(data.numberOfSteps)"
                        print("Steps done in the previous 30 min: \(data.numberOfSteps)")
                    }
                }
            }
        }
    }
}

//IDEAS - TO DO

//initialize step count depending on the stepcount of the week before during work - use PERSONAL phone if possible
//


