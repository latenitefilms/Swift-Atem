//
//  File.swift
//  
//
//  Created by Damiaan on 11/06/2020.
//

import Atem
import Dispatch

func connect(ip: String) throws -> Controller {
	let initialisation = DispatchGroup()
	initialisation.enter()

	let controller = try Controller(forSwitcherAt: ip) { connection in
		connection.when{ (change: Did.ChangePreviewBus) in
			print(change) // prints: 'Preview bus changed to input(x)'
		}

		connection.when { (connected: Config.InitiationComplete) in
			print(connected)
			initialisation.leave()
		}

		connection.whenDisconnected = {
			print("Disconnected")
		}
	}

	initialisation.wait()
	return controller
}
