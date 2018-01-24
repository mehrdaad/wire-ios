//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
extension StartUIViewController: SearchResultsViewControllerDelegate {
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnUser user: ZMSearchableUser, indexPath: IndexPath, section: SearchResultsViewControllerSection) {
        if user is AnalyticsConnectionStateProvider, let user: AnalyticsConnectionStateProvider = user as? AnalyticsConnectionStateProvider {
            Analytics.shared().tagSelectedUnconnectedUser(with: user, context: .startUI)
        }
        switch section {
        case .topPeople:
            Analytics.shared().tagSelectedTopContact()
        case .contacts:
            Analytics.shared().tagSelectedSearchResultUser(with: UInt(indexPath.row))
        case .directory:
            Analytics.shared().tagSelectedSuggestedUser(with: UInt(indexPath.row))
        default:
            break
        }
        if !(user.isConnected && !user.isTeamMember) {
            presentProfileViewController(for: user, at: indexPath)
        }
    }

    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnConversation conversation: ZMConversation) {
        guard delegate.responds(to: #selector(StartUIDelegate.startUI(_:didSelect:))) else { return }

        if conversation.conversationType == .group {
            delegate.startUI!(self, didSelect: conversation)
        }
    }

    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnSeviceUser serviceUser: ServiceUser) {
        let confirmButton = Button(styleClass: "dialogue-button-full")
        confirmButton.setTitle("peoplepicker.services.add_service.button".localized, for: .normal)

        let buttonCallback: Callback<Button> = { [weak self] _ in
            guard let userSession = ZMUserSession.shared() else {
                return
            }

            var allConversations: [ServiceConversation] = [.new]

            let zmConversations = ZMConversationList.conversationsIncludingArchived(inUserSession: userSession).shareableConversations()

            allConversations.append(contentsOf: zmConversations.map(ServiceConversation.existing))

            let conversationPicker = ShareViewController<ServiceConversation, Service>(shareable: Service(serviceUser: serviceUser), destinations: allConversations, showPreview: true, allowsMultiselect: false)
            conversationPicker.onDismiss = { [weak self] _, completed in
                self?.navigationController?.dismiss(animated: true, completion: nil)
            }
            self?.navigationController?.pushViewController(conversationPicker, animated: true)
        }

        let serviceDetail = ServiceDetailViewController(serviceUser: serviceUser, backgroundColor: .clear, textColor: .white, confirmButton: confirmButton, forceShowNavigationBarWhenviewWillAppear: true, buttonCallback: buttonCallback)

        serviceDetail.completion = {(_ conversation: ZMConversation?) -> Void in
            if let conversation = conversation {
                if self.delegate.responds(to: #selector(StartUIDelegate.startUI(_:didSelect:))) {
                    self.delegate.startUI!(self, didSelect: conversation)
                }
            }
        }
        navigationController?.pushViewController(serviceDetail, animated: true)
    }

    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didDoubleTapOnUser user: ZMSearchableUser, indexPath: IndexPath) {
        guard let unboxedUser: ZMUser = BareUserToUser(user) else { return }
        guard delegate.responds(to: #selector(StartUIDelegate.startUI(_:didSelectUsers:for:))) else { return }

        if (unboxedUser.isConnected) && !unboxedUser.isBlocked {
            if self.userSelection.users.count == 1 && !userSelection.users.contains(unboxedUser ) {
                return
            }
            ///FIXME: compile crash?
            //            delegate.startUI(self, didSelectUsers: Set<AnyHashable>([user]), forAction: .createOrOpenConversation)
        }
    }
}
