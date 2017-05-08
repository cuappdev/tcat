//
//  CornellDestinationCell.swift
//  TCAT
//
//  Created by Austin Astorga on 5/7/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit

class CornellDestinationCell: UITableViewCell {

    let labelWidthConstant = CGFloat(45.0)
    let labelXPosition = CGFloat(40.0)
    let imageHeight = CGFloat(20.0)
    let imageWidth = CGFloat(20.0)
    let labelHeight = CGFloat(20.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView?.frame = CGRect(x: 10, y: 5, width: imageWidth, height: imageHeight)
        imageView?.contentMode = .scaleAspectFit
        imageView?.center.y = bounds.height / 2.0
        imageView?.image = #imageLiteral(resourceName: "bus")
        imageView?.tintColor = .tcatBlueColor 
        
        textLabel?.frame = CGRect(x: labelXPosition, y: 8.0, width: frame.width - labelWidthConstant, height: labelHeight)
        textLabel?.font = .systemFont(ofSize: 13)
        
        detailTextLabel?.frame = CGRect(x: labelXPosition, y: 0, width: frame.width - labelWidthConstant, height: labelHeight)
        detailTextLabel?.center.y = bounds.height - 15.0
        detailTextLabel?.textColor = UIColor(white: 153.0 / 255.0, alpha: 1.0)
        detailTextLabel?.font = .systemFont(ofSize: 12)
    }


}
