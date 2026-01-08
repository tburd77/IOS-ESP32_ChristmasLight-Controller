//
//  SelectableObject.swift
//  Christmas Light Controller
//
//  Created by Terry Burdett on 12/13/25.
//


import UIKit

/*struct SelectableObject {
    let id: Int
    let name: String
}*/

class ColorPickerViewController: UIViewController {

    // MARK: - UI

    @IBOutlet weak var previewView: UIView!
    @IBAction func redSlider(_ sender: Any) {
    }
    @IBAction func greenSlider(_ sender: Any) {
    }
    @IBAction func blueSlider(_ sender: Any) {
    }
    
    @IBOutlet weak var channel_Outlet: UISegmentedControl!
    @IBAction func channel(_ sender: Any) {
        switch channel_Outlet.selectedSegmentIndex
        {
        case 0: channelSelected = 0
        case 1: channelSelected = 1
        default:
            break
        }
      //  channelSelected =  channel_Outlet.selectedSegmentIndex
    }
    @IBOutlet weak var blueSlider_Outlet: UISlider!
    @IBOutlet weak var greenSlider_Outlet: UISlider!
    @IBOutlet weak var redSlider_Outlet: UISlider!
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Data
    let objects: [String] = [
        "RGB",
        "Rainbow",
        "Chase",
        "LarsonScanner",
        "PaletteCrossfade",
        "Sparkle",
        "Twinkle",
        "Fire2012",
       // "FadeStep",
        "Random"
    ]
    var selectedIndexPath: IndexPath?
    var channelSelected = 0
    private var selectedRow = 0
  

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = selectedDeviceID//"RGB Controller"
        view.backgroundColor = .systemBackground
     
        setupUI()
        updatePreview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        selectedRow = 0
        if let indexPath = selectedIndexPath {
               tableView.selectRow(
                   at: indexPath,
                   animated: false,
                   scrollPosition: .none
               )
           }
    }
    
    @objc private func sliderChanged() {
        updatePreview()
       // sendColorIfReady()
    }

    private func updatePreview() {
        previewView.backgroundColor = currentColor
    }

    private var currentColor: UIColor {
        UIColor(
            red: CGFloat(redSlider_Outlet.value / 255),
            green: CGFloat(greenSlider_Outlet.value / 255),
            blue: CGFloat(blueSlider_Outlet.value / 255),
            alpha: 1
        )
    }

    private func sendColorIfReady() {
   
        if selectedRow < objects.count {

            let r = Int(redSlider_Outlet.value)
            let g = Int(greenSlider_Outlet.value)
            let b = Int(blueSlider_Outlet.value)
            
            var command = ""
            if selectedRow == 0 {
                command = "\(channelSelected) RGB \(r) \(g) \(b)\n"
            }else {
              //  if selectedRow == 0 {
               //     command = "\(channelSelected) STEADY \(r) \(g) \(b)\n"
               // }else {
                command = String(channelSelected) + " " + objects[selectedRow]
               // }
            }
            bleSendText = command
            NotificationCenter.default.post(name: Notification.Name(rawValue: "setColor"), object: nil)
        }
  
    }

    
}

private extension ColorPickerViewController {

    func setupUI() {

        previewView.layer.cornerRadius = 12
        previewView.layer.borderWidth = 1
        previewView.layer.borderColor = UIColor.secondaryLabel.cgColor

        [redSlider_Outlet, greenSlider_Outlet, blueSlider_Outlet].forEach {
            $0.minimumValue = 0
            $0.maximumValue = 255
            $0.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        }
        
        blueSlider_Outlet.value = 255

        redSlider_Outlet.tintColor = .systemRed
        greenSlider_Outlet.tintColor = .systemGreen
        blueSlider_Outlet.tintColor = .systemBlue

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
    }

}

extension ColorPickerViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        objects.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = objects[indexPath.row]
        
     //   cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
            
        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        
        selectedRow = indexPath.row
        selectedIndexPath = indexPath
        
        tableView.reloadData()
        sendColorIfReady()
    }
}
