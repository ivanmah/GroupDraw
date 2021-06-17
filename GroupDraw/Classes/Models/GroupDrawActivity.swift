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
            var metadata = GroupActivityMetadata()
            metadata.type = .generic
            metadata.title = "GroupDraw"
            metadata.previewImage = UIImage(systemName: "scribble")?.cgImage

            return metadata
        }
    }
}
