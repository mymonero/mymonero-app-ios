//
//  ListedObject.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
protocol ListedObjectInsertDescription
{
}
//
protocol ListedObject
{
	// (read existing)
	init?(withDictRepresentation dictRepresentation: DocumentPersister.DocumentJSON) throws
	// -OR- (insert)
	static func new(withInsertDescription description: ListedObjectInsertDescription) -> (
		err_str: String?,
		listedObject: ListedObject?
	)
}
