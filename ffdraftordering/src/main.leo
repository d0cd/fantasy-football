// The 'ffdraftordering' program.
program ffdraftordering_v1_0_0.aleo {
    record Ticket {
        owner: address;
        player: address;
        seed: field;
        public tag: field;
    }

    struct DraftOrder {
        first: address,
        second: address,
        third: address,
        fourth: address,
        fifth: address,
        sixth: address,
        seventh: address,
        eighth: address,
        ninth: address,
        tenth: address,
    }

    struct U32Bits {
        b0: bool, b1: bool, b2: bool, b3: bool, b4: bool, b5: bool, b6: bool, b7: bool,
        b8: bool, b9: bool, b10: bool, b11: bool, b12: bool, b13: bool, b14: bool, b15: bool,
        b16: bool, b17: bool, b18: bool, b19: bool, b20: bool, b21: bool, b22: bool, b23: bool,
        b24: bool, b25: bool, b26: bool, b27: bool, b28: bool, b29: bool, b30: bool, b31: bool,
    }

    transition register(seed: field, tag: field) -> Ticket {
        return Ticket {
            owner: aleo1xuzjjrckyyy6qw263l67c0mlmy7utf0pkzw6fgwyjuynju2vsvpqk74z7f, // TODO: Switch with league manager's address.
            player: self.caller,
            seed,
            tag,
        };
    }

    transition determine_draft_order(
        ticket0: Ticket, 
        ticket1: Ticket, 
        ticket2: Ticket,
        ticket3: Ticket,
        ticket4: Ticket,
        ticket5: Ticket,
        ticket6: Ticket,
        ticket7: Ticket,
        ticket8: Ticket,
        ticket9: Ticket,
        bits: U32Bits,
    ) -> public DraftOrder {
        // Check that the tickets are provided in lexicographic order (by `player`).
        // This ensures that the league manager cannot reorder tickets to their advantage.
        assert((ticket0.player as field) < (ticket1.player as field));
        assert((ticket1.player as field) < (ticket2.player as field));
        assert((ticket2.player as field) < (ticket3.player as field));
        assert((ticket3.player as field) < (ticket4.player as field));
        assert((ticket4.player as field) < (ticket5.player as field));
        assert((ticket5.player as field) < (ticket6.player as field));
        assert((ticket6.player as field) < (ticket7.player as field));
        assert((ticket7.player as field) < (ticket8.player as field));
        assert((ticket8.player as field) < (ticket9.player as field));

        // Construct the seed.
        let seed: field = ticket0.seed + ticket1.seed + ticket2.seed + ticket3.seed + ticket4.seed + ticket5.seed + ticket6.seed + ticket7.seed + ticket8.seed + ticket9.seed;

        // Construct the default draft order.
        let order: DraftOrder = DraftOrder {
            first: ticket0.player,
            second: ticket1.player,
            third: ticket2.player,
            fourth: ticket3.player,
            fifth: ticket4.player,
            sixth: ticket5.player,
            seventh: ticket6.player,
            eighth: ticket7.player,
            ninth: ticket8.player,
            tenth: ticket9.player,
        };

        // Hash the seed and cast it to a u32.
        let hash: u32 = BHP256::hash_to_u32(seed);

        // Check that the input bits are reconstructed to the `hash`.
        check_bits(hash, bits);

        // Shuffle the draft order.
        // Shuffling is performed using a Waksman network, initialized with random control bits.
        let shuffled_order: DraftOrder = shuffle(order, bits);

        // Return the shuffled draft order.
        return shuffled_order;
    }

    // A helper function to shuffle the draft order.
    inline shuffle(
        starting_order: DraftOrder,
        bits: U32Bits,
    ) -> DraftOrder {
        let (w0, w1): (address, address) = waksman2(bits.b0, starting_order.first, starting_order.second);
        let (w2, w3): (address, address) = waksman2(bits.b1, starting_order.third, starting_order.fourth);
        let (w4, w5): (address, address) = waksman2(bits.b2, starting_order.fifth, starting_order.sixth);
        let (w6, w7): (address, address) = waksman2(bits.b3, starting_order.seventh, starting_order.eighth);
        let (w8, w9): (address, address) = waksman2(bits.b4, starting_order.ninth, starting_order.tenth);

        let (w10, w11, w12, w13, w14): (address, address, address, address, address) = waksman5(
            bits.b5, bits.b6, bits.b7, bits.b8, bits.b9, bits.b10, bits.b11, bits.b12,
            w0, w2, w4, w6, w8,
        );
        let (w15, w16, w17, w18, w19): (address, address, address, address, address) = waksman5(
            bits.b13, bits.b14, bits.b15, bits.b16, bits.b17, bits.b18, bits.b19, bits.b20,
            w1, w3, w5, w7, w9,
        );

        let (w20, w21): (address, address) = waksman2(bits.b21, w10, w15);
        let (w22, w23): (address, address) = waksman2(bits.b22, w11, w16);
        let (w24, w25): (address, address) = waksman2(bits.b23, w12, w17);
        let (w26, w27): (address, address) = waksman2(bits.b24, w13, w18);
        let (w28, w29): (address, address) = waksman2(bits.b25, w14, w19);

        return DraftOrder {
            first: w20,
            second: w21,
            third: w22,
            fourth: w23,
            fifth: w24,
            sixth: w25,
            seventh: w26,
            eighth: w27,
            ninth: w28,
            tenth: w29,
        };
    }

    // A helper function to run a Waksman network with five inputs.
    inline waksman5(
        b0: bool, b1: bool, b2: bool, b3: bool, b4: bool, b5: bool, b6: bool, b7: bool,
        first: address, second: address, third: address, fourth: address, fifth: address,
    ) -> (address, address, address, address, address) {
        let (w0, w1): (address, address) = waksman2(b0, first, second);
        let (w2, w3): (address, address) = waksman2(b1, third, fourth);
        let (w4, w5): (address, address) = waksman2(b2, w0, w2);
        let (w6, w7, w8): (address, address, address) = waksman3(b3, b4, b5, w1, w3, fifth);
        let (w9, w10): (address, address) = waksman2(b6, w4, w6);
        let (w11, w12): (address, address) = waksman2(b7, w5, w7);
        return (w9, w10, w11, w12, w8);
    }

    // A helper function to run a Waksman network with three inputs.
    inline waksman3(b0: bool, b1: bool, b2: bool, first: address, second: address, third: address) -> (address, address, address) {
        let (w0, w1): (address, address) = waksman2(b0, first, second);
        let (w2, w3): (address, address) = waksman2(b1, w1, third);
        let (w4, w5): (address, address) = waksman2(b2, w0, w2);
        return (w4, w5, w3);
    }

    // A helper function to run a Waksman network with two inputs, in other words, a switch.
    inline waksman2(bit: bool, first: address, second: address) -> (address, address) {
        if bit {
            return (second, first);
        } else {
            return (first, second);
        }
    }

    // A helper function to check that the witnessed `bits` correspond to the given number.
    inline check_bits(number: u32, bits: U32Bits) {
        assert((bits.b0 ? 1u32 : 0u32) == (number & 1u32));
        assert((bits.b1 ? 1u32 : 0u32) == (number & 2u32));
        assert((bits.b2 ? 1u32 : 0u32) == (number & 4u32));
        assert((bits.b3 ? 1u32 : 0u32) == (number & 8u32));
        assert((bits.b4 ? 1u32 : 0u32) == (number & 16u32));
        assert((bits.b5 ? 1u32 : 0u32) == (number & 32u32));
        assert((bits.b6 ? 1u32 : 0u32) == (number & 64u32));
        assert((bits.b7 ? 1u32 : 0u32) == (number & 128u32));
        assert((bits.b8 ? 1u32 : 0u32) == (number & 256u32));
        assert((bits.b9 ? 1u32 : 0u32) == (number & 512u32));
        assert((bits.b10 ? 1u32 : 0u32) == (number & 1024u32));
        assert((bits.b11 ? 1u32 : 0u32) == (number & 2048u32));
        assert((bits.b12 ? 1u32 : 0u32) == (number & 4096u32));
        assert((bits.b13 ? 1u32 : 0u32) == (number & 8192u32));
        assert((bits.b14 ? 1u32 : 0u32) == (number & 16384u32));
        assert((bits.b15 ? 1u32 : 0u32) == (number & 32768u32));
        assert((bits.b16 ? 1u32 : 0u32) == (number & 65536u32));
        assert((bits.b17 ? 1u32 : 0u32) == (number & 131072u32));
        assert((bits.b18 ? 1u32 : 0u32) == (number & 262144u32));
        assert((bits.b19 ? 1u32 : 0u32) == (number & 524288u32));
        assert((bits.b20 ? 1u32 : 0u32) == (number & 1048576u32));
        assert((bits.b21 ? 1u32 : 0u32) == (number & 2097152u32));
        assert((bits.b22 ? 1u32 : 0u32) == (number & 4194304u32));
        assert((bits.b23 ? 1u32 : 0u32) == (number & 8388608u32));
        assert((bits.b24 ? 1u32 : 0u32) == (number & 16777216u32));
        assert((bits.b25 ? 1u32 : 0u32) == (number & 33554432u32));
        assert((bits.b26 ? 1u32 : 0u32) == (number & 67108864u32));
        assert((bits.b27 ? 1u32 : 0u32) == (number & 134217728u32));
        assert((bits.b28 ? 1u32 : 0u32) == (number & 268435456u32));
        assert((bits.b29 ? 1u32 : 0u32) == (number & 536870912u32));
        assert((bits.b30 ? 1u32 : 0u32) == (number & 1073741824u32));
        assert((bits.b31 ? 1u32 : 0u32) == (number & 2147483648u32));
    }
}
