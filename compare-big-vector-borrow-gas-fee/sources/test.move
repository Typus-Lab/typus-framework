module test::test {
    use std::vector;

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    use typus_framework::big_vector::{Self, BigVector};

    struct Test has key, store {
        id: UID,
        big_vector: BigVector<u64>,
    }

    fun init(ctx: &mut TxContext) {
        let big_vector = big_vector::new(1000, ctx);
        let i = 0;
        while (i < 50000) {
            big_vector::push_back(&mut big_vector, i);
            i = i + 1;
        };
        let test = Test { id: object::new(ctx), big_vector };
        transfer::share_object(test);
    }

    entry fun test_1(test: &mut Test) {
        let length = big_vector::length(&test.big_vector);
        let i = 0;
        while (i < length) {
            // update value
            let value = big_vector::borrow_mut(&mut test.big_vector, i);
            *value = *value + 1;
            i = i + 1;
        };
    }

    entry fun test_2(test: &mut Test) {
        let length = big_vector::length(&test.big_vector);
        let slice_size = big_vector::slice_size(&test.big_vector);
        let slice = big_vector::borrow_slice_mut(&mut test.big_vector, 1);
        let i = 0;
        while (i < length) {
            // update value
            let value = vector::borrow_mut(slice, i % slice_size);
            *value = *value + 1;
            // check index and iterate to next slice
            if (i + 1 < length && (i + 1) % slice_size == 0) {
                let slice_id = big_vector::slice_id(&test.big_vector, i + 1);
                slice = big_vector::borrow_slice_mut(
                    &mut test.big_vector,
                    slice_id,
                );
            };
            i = i + 1;
        };
    }
}