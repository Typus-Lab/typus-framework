// Copyright (c) Typus Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module typus_framework::authority {
    use std::vector;
    use std::option;
    use sui::tx_context::{Self, TxContext};
    use sui::linked_table::{Self, LinkedTable};

    // ======== Errors ========

    const E_EMPTY_WHITELIST: u64 = 0;

    // ======== Structs ========

    struct Authority has store {
        whitelist: LinkedTable<address, bool>,
    }

    // ======== Functions ========

    /// create Authority with at least one whitelist user
    public fun new(
        whitelist: vector<address>,
        ctx: &mut TxContext
    ): Authority {
        let wl = linked_table::new(ctx);
        if (vector::is_empty(&whitelist)) {
            abort E_EMPTY_WHITELIST
        };
        while (!vector::is_empty(&whitelist)) {
            let user_address = vector::pop_back(&mut whitelist);
            if (!linked_table::contains(&wl, user_address)) {
                linked_table::push_back(&mut wl, user_address, true);
            }
        };
        Authority {
            whitelist: wl,
        }
    }

    /// verify user
    public fun verify(authority: &Authority, ctx: &TxContext): bool {
        linked_table::contains(&authority.whitelist, tx_context::sender(ctx))
    }

    /// add whitelist
    public fun add_authorized_user(
        authority: &mut Authority,
        user_address: address,
    ) {
        if (!linked_table::contains(&authority.whitelist, user_address)) {
            linked_table::push_back(&mut authority.whitelist, user_address, true);
        }
    }

    /// remove whitelist
    public fun remove_authorized_user(
        authority: &mut Authority,
        user_address: address,
    ) {
        if (linked_table::contains(&authority.whitelist, user_address)) {
            linked_table::remove(&mut authority.whitelist, user_address);
        };
        if (linked_table::is_empty(&authority.whitelist)) {
            abort E_EMPTY_WHITELIST
        };
    }

    /// get all whitelist users
    public fun whitelist(authority: &Authority): vector<address> {
        let whitelist = vector::empty();
        let key = linked_table::front(&authority.whitelist);
        while (option::is_some(key)) {
            let user_address = option::borrow(key);
            vector::push_back(
                &mut whitelist,
                *user_address,
            );
            key = linked_table::next(&authority.whitelist, *user_address);
        };
        whitelist
    }

    /// drop Authority
    public fun destroy(
        authority: Authority,
    ) {
        let Authority { whitelist } = authority;
        while (linked_table::length(&whitelist) > 0) {
            linked_table::pop_front(&mut whitelist);
        };
        linked_table::destroy_empty(whitelist);
    }
}