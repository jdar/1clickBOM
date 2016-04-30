# The contents of this file are subject to the Common Public Attribution
# License Version 1.0 (the “License”); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://1clickBOM.com/LICENSE. The License is based on the Mozilla Public
# License Version 1.1 but Sections 14 and 15 have been added to cover use of
# software over a computer network and provide for limited attribution for the
# Original Developer. In addition, Exhibit A has been modified to be consistent
# with Exhibit B.
#
# Software distributed under the License is distributed on an
# "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations under
# the License.
#
# The Original Code is 1clickBOM.
#
# The Original Developer is the Initial Developer. The Original Developer of
# the Original Code is Kaspar Emanuel.

{writeTSV}      = require '1-click-bom'
{retailer_list} = require('1-click-bom').lineData

{bom_manager} = require './bom_manager'
{browser}     = require './browser'
http          = require './http'
{badge}       = require './badge'

exports.background = (messenger) ->
    browser.prefsOnChanged ['country', 'settings'], () ->
        bom_manager.init()

    sendState = () ->
        bom_manager.getBOM (bom) ->
            messenger.send('sendBackgroundState',
                bom        : bom
                interfaces : bom_manager.interfaces
                onDotTSV   : tsvPageNotifier.onDotTSV)
            messenger.send('updateKitnic', bom_manager.interfaces)

    tsvPageNotifier = require('./tsv_page_notifier').tsvPageNotifier(sendState, bom_manager)

    browser.tabsOnUpdated () =>
        tsvPageNotifier.checkPage()

    autoComplete = (deep=false) ->
        finish = (timeout_id, no_of_completed) ->
            browser.clearTimeout(timeout_id)
            sendState()
            if no_of_completed > 0
                browser.notificationsCreate
                    type    : 'basic'
                    title   : 'Auto-complete successful'
                    message : "Completed #{no_of_completed} fields for you
                        by searching Octopart and Findchips."
                    iconUrl : '/images/ok.png'
                badge.setDecaying('OK','#00CF0F')
            else
                browser.notificationsCreate
                    type    : 'basic'
                    title   : 'Auto-complete returned 0 results'
                    message : 'Could not complete any fields for you.'
                    iconUrl : '/images/warning.png'
                badge.setDecaying('Warn','#FF8A00')
        timeout_id = browser.setTimeout () ->
            promise.cancel()
            finish(timeout_id, 0)
        , 180000
        promise = bom_manager.autoComplete(deep)
        promise.then (no_of_completed) ->
            finish(timeout_id, no_of_completed)

    emptyCart = (name) ->
        bom_manager.interfaces[name].clearing_cart = true
        timeout_id = browser.setTimeout ((name) ->
            bom_manager.interfaces[name].clearing_cart = false
            sendState()
        ).bind(null, name)
        , 180000
        bom_manager.emptyCart name, ((name, timeout_id) ->
            browser.clearTimeout(timeout_id)
            bom_manager.interfaces[name].clearing_cart = false
            bom_manager.interfaces[name].openCartTab()
            sendState()
        ).bind(null, name, timeout_id)
        sendState()

    fillCart = (name) ->
        bom_manager.interfaces[name].adding_lines = true
        timeout_id = browser.setTimeout ((name) ->
            bom_manager.interfaces[name].adding_lines = false
            sendState()
        ).bind(null, name)
        , 180000
        bom_manager.fillCart name, ((name, timeout_id) ->
            browser.clearTimeout(timeout_id)
            bom_manager.interfaces[name].adding_lines = false
            bom_manager.interfaces[name].openCartTab()
            sendState()
        ).bind(null, name, timeout_id)
        sendState()

    messenger.on 'getBackgroundState', () ->
        sendState()

    messenger.on('fillCart', fillCart)

    messenger.on 'openCart', (name) ->
        bom_manager.interfaces[name].openCartTab()

    messenger.on 'deepAutoComplete', () ->
        autoComplete(deep=true)

    messenger.on('emptyCart', emptyCart)

    messenger.on 'clearBOM', () ->
        browser.storageRemove 'bom' , () ->
            sendState()

    messenger.on 'paste', () ->
        bom_manager.addToBOM browser.paste(), () ->
            sendState()

    messenger.on 'copy', () ->
        bom_manager.getBOM (bom) ->
            browser.copy(writeTSV(bom.lines))
            badge.setDecaying('OK','#00CF0F')

    messenger.on 'loadFromPage', () ->
        tsvPageNotifier.addToBOM () ->
            sendState()

    messenger.on 'loadFromRef', (ref) ->
        browser.notificationsCreate
            type    : 'basic'
            title   : 'added '+ref
            message : 'added '+ref+' to BOM and ... .'
            iconUrl : '/images/ok.png'

    messenger.on 'emptyCarts', () ->
        for name in retailer_list
            emptyCart(name)

    messenger.on 'fillCarts', () ->
        for name in retailer_list
            fillCart(name)

    messenger.on 'quickAddToCart', (retailer) ->
        tsvPageNotifier.quickAddToCart(retailer)

    sendState()
