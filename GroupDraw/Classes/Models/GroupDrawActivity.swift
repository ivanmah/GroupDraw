//
//  GroupDrawActivity.swift
//  GroupDraw
//
//  Created by Ivan Mah on 10/6/21.
//

import GroupActivities
import UIKit

struct GroupDrawActivity: GroupActivity {
    var metadata: GroupActivityMetadata {
        get async {
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 200)
            let image = UIImage(systemName: "pencil.and.outline", withConfiguration: symbolConfiguration)
            
            var metadata = GroupActivityMetadata()
            metadata.type = .generic
            metadata.title = "GroupDraw"
            metadata.previewImage = image?.cgImage

            return metadata
        }
    }
}
