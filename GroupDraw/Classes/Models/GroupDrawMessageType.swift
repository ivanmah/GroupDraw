//
//  GroupDrawMessageType.swift
//  GroupDraw
//
//  Created by Ivan Mah on 10/6/21.
//

import PencilKit

enum GroupDrawMessageType: Codable {
    case draw(drawing: PKDrawing)
    case catchup(drawing: PKDrawing)
    case erase
    case clear
}
