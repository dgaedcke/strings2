//
//  HomeViewController.swift
//  Strings2
//
//  Created by Dewey Gaedcke on 12/27/16.
//  Copyright © 2016 Dewey Gaedcke. All rights reserved.
//

import UIKit

class HomeViewController: AppViewController {

	
	@IBAction func resetHelpButton(_ sender: UIButton) {
		toggleHelp()
	}
	
	@IBAction func geoFenceButton(_ sender: UIButton) {
		
	}
	
	@IBAction func feature3Button(_ sender: UIButton) {
		
	}
	
	@IBAction func ibDesignableBtnAction(_ sender: UIButton) {
		resetAllHelpShown()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()


    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
