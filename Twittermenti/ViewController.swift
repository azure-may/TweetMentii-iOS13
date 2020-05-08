//
//  ViewController.swift
//  Twittermenti
//
//  Created by Angela Yu on 17/07/2019.
//  Copyright © 2019 London App Brewery. All rights reserved.
//

import UIKit
import SwifteriOS
import CoreML
//import SwiftyJSON

@available(iOS 12.0, *)
class ViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    private let swifter = Swifter(consumerKey: Secrets.key, consumerSecret: Secrets.secret)
    private let sentimentClassifier = TweetSentimentClassifier()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func predictPressed(_ sender: Any) {
        if let text = textField.text {
            fetchTweets(text)
            textField.text = ""
        }
    }
    
    private func fetchTweets(_ searchTerm: String) {
        swifter.searchTweet(using: searchTerm, lang: K.lang, resultType: K.period, count: K.count, includeEntities: false, tweetMode: .extended, success: { (results, metadata) in
            var tweets = [TweetSentimentClassifierInput]()
            for i in 0..<K.count {
                if let tweet = results[i][K.textType].string {
                    let input = TweetSentimentClassifierInput(text: tweet)
                    tweets.append(input)
                }
            }
            self.generatePrediction(tweets)
        }) { (error) in
            print("Error processing API request: \(error)")
        }
    }
    
    private func generatePrediction(_ tweetTextArray: [TweetSentimentClassifierInput]) {
        do {
            let predictions = try self.sentimentClassifier.predictions(inputs: tweetTextArray)
            var score: Int = 0
            for prediction in predictions {
                if prediction.label == "Pos" {
                    score += 1
                } else if prediction.label == "Neg" {
                    score -= 1
                }
            }
            let scorePercentile = Double(score) / Double(K.count)
            self.updateSentiment(scorePercentile)
        } catch {
            print("Error classifying tweets: \(error)")
        }
    }
    
    private func updateSentiment(_ percentile: Double) {
        var index: Int = 4
        switch percentile {
        case -1.00 ... -0.76 :
            index = 0
        case -0.75 ... -0.51 :
            index = 1
        case -0.50 ... -0.26 :
            index = 2
        case -0.25 ... -0.06 :
            index = 3
        case -0.05 ... 0.05 :
            index = 4
        case 0.06 ... 0.25 :
            index = 5
        case 0.26 ... 0.50 :
            index = 6
        case 0.51 ... 0.75 :
            index = 7
        case 0.76 ... 1.00 :
            index = 8
        default:
            index = 4
        }
        DispatchQueue.main.async {
            self.sentimentLabel.text = K.emoji[index]
        }
    }
}

