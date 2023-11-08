// Copyright (c) Typus Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module typus_framework::utils {
    use std::type_name;
    use std::vector;

    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};

    // ======== Constants ========

    const C_MONTH_STRING: vector<vector<u8>> = vector[
        b"JAN", b"FEB", b"MAR", b"APR", b"MAY", b"JUN",
        b"JUL", b"AUG", b"SEP", b"OCT", b"NOV", b"DEC"
    ];
    const C_NUMBER_STRING: vector<vector<u8>> = vector[
        b"00", b"01", b"02", b"03", b"04", b"05", b"06", b"07", b"08", b"09",
        b"10", b"11", b"12", b"13", b"14", b"15", b"16", b"17", b"18", b"19",
        b"20", b"21", b"22", b"23", b"24", b"25", b"26", b"27", b"28", b"29",
        b"30", b"31", b"32", b"33", b"34", b"35", b"36", b"37", b"38", b"39",
        b"40", b"41", b"42", b"43", b"44", b"45", b"46", b"47", b"48", b"49",
        b"50", b"51", b"52", b"53", b"54", b"55", b"56", b"57", b"58", b"59",
        b"60", b"61", b"62", b"63", b"64", b"65", b"66", b"67", b"68", b"69",
        b"70", b"71", b"72", b"73", b"74", b"75", b"76", b"77", b"78", b"79",
        b"80", b"81", b"82", b"83", b"84", b"85", b"86", b"87", b"88", b"89",
        b"90", b"91", b"92", b"93", b"94", b"95", b"96", b"97", b"98", b"99"
    ];

    // ======== Errors ========

    const E_INSUFFICIENT_BALANCE: u64 = 0;

    // ======== Functions ========

    /// extract balance from multiple coin objects
    public fun extract_balance<Token>(coins: vector<Coin<Token>>, amount: u64, ctx: &TxContext): Balance<Token> {
        let balance = balance::zero();
        while (!vector::is_empty(&coins)) {
            if (amount > 0) {
                let coin = vector::pop_back(&mut coins);
                if (coin::value(&coin) >= amount) {
                    balance::join(&mut balance, balance::split(coin::balance_mut(&mut coin), amount));
                    vector::push_back(&mut coins, coin);
                    amount = 0;
                    break
                }
                else {
                    amount = amount - coin::value(&coin);
                    balance::join(&mut balance, coin::into_balance(coin));
                };
            }
            else {
                break
            }
        };
        assert!(amount == 0, E_INSUFFICIENT_BALANCE);
        let user = tx_context::sender(ctx);
        while (!vector::is_empty(&coins)) {
            let coin = vector::pop_back(&mut coins);
            transfer::public_transfer(coin, user);
        };
        vector::destroy_empty(coins);
        balance
    }

    /// reference: http://howardhinnant.github.io/date_algorithms.html#civil_from_days
    public fun get_date_from_ts(timestamp: u64): (u64, u64, u64) {
        let z = timestamp / 86400 + 719468;
        let era = z / 146097;
        let doe = z - era * 146097;
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        let y = yoe + era * 400;
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        let mp = (5 * doy + 2) / 153;
        let d = doy - (153 * mp + 2) / 5 + 1;
        let m = if (mp < 10) { mp + 3 } else { mp - 9 };
        let y = if (m <= 2) { y + 1 } else { y };
        (y, m, d)
    }

    /// check if type X equals type Y
    public fun match_types<X, Y>(): bool {
        type_name::get<X>() == type_name::get<Y>()
    }

    /// transfer u64 to string bytes
    public fun u64_to_bytes(value: u64, decimal: u64): vector<u8> {
        let result = vector::empty();
        while (decimal > 0) {
            let digit = value % 10;
            if (!vector::is_empty(&result) || digit != 0) {
                vector::push_back(&mut result, (digit as u8) + 48);
            };
            value = value / 10;
            decimal = decimal - 1;
        };
        if (!vector::is_empty(&result)) {
            vector::push_back(&mut result, 46);
        };
        if (value == 0) {
            vector::push_back(&mut result, 48);
        } else {
            while (value > 0) {
                let digit = value % 10;
                vector::push_back(&mut result, (digit as u8) + 48);
                value = value / 10;
            }
        };
        vector::reverse(&mut result);

        result
    }

    /// get month abbreviations
    public fun get_month_short_string(month: u64): vector<u8> {
        *vector::borrow(&C_MONTH_STRING, month - 1)
    }

    /// get u64 pad 2 string bytes
    public fun get_pad_2_number_string(value: u64): vector<u8> {
        *vector::borrow(&C_NUMBER_STRING, value % 100)
    }

    // ======== Tests ========

    #[test]
    fun test_get_date_from_ts() {
        let (y, m, d) = get_date_from_ts(726386766);
        assert!(y == 1993, 0);
        assert!(m == 1, 0);
        assert!(d == 7, 0);
        let (y, m, d) = get_date_from_ts(1458457627);
        assert!(y == 2016, 0);
        assert!(m == 3, 0);
        assert!(d == 20, 0);
        let (y, m, d) = get_date_from_ts(1671280200);
        assert!(y == 2022, 0);
        assert!(m == 12, 0);
        assert!(d == 17, 0);
    }

    #[test]
    fun test_u64_to_bytes() {
        let bytes = u64_to_bytes(165011022030, 8);
        assert!(bytes == b"1650.1102203", 0);
        let bytes = u64_to_bytes(75305129, 9);
        assert!(bytes == b"0.075305129", 0);
        let bytes = u64_to_bytes(74500, 8);
        assert!(bytes == b"0.000745", 0);
    }
}