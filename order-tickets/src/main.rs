use snarkvm::prelude::*;
use snarkvm::console::network::ToField;
use snarkvm::console::network::ToBits;

type CurrentNetwork = Testnet3;

fn main() {

    let record_text = [
     // TODO: Input decrypted records here.
    ];

    // Parse the records.
    let mut records = record_text
        .iter()
        .map(|text| Record::from_str(*text).unwrap())
        .collect::<Vec<Record<CurrentNetwork, Plaintext<CurrentNetwork>>>>();

    // Sort the records by player.
    records.sort_by(|a, b| {
        let first = match a.find(&[Identifier::from_str("player").unwrap()]).unwrap() {
            Entry::Private(Plaintext::Literal(Literal::Address(first), _)) => first,
            _ => panic!("expected field")
        };
        let second = match b.find(&[Identifier::from_str("player").unwrap()]).unwrap() {
            Entry::Private(Plaintext::Literal(Literal::Address(second), _)) => second,
            _ => panic!("expected field")
        };
        first.to_field().unwrap().cmp(&second.to_field().unwrap())
    });

    // Get the seeds from each record and sum them.
    let aggregate_seed = Value::Plaintext(Plaintext::from(Literal::Field(records
        .iter()
        .map(|record| {
            let seed = match record.find(&[Identifier::from_str("seed").unwrap()]).unwrap() {
                Entry::Private(Plaintext::Literal(Literal::Field(seed), _)) => seed,
                _ => panic!("expected field")
            };
            seed
        })
        .sum::<Field<CurrentNetwork>>())));

    // Compute a BHP256 hash over the seed and convert it to a U32 literal.
    let number = Literal::Group(Testnet3::hash_to_group_bhp256(&aggregate_seed.to_bits_le()).unwrap()).downcast_lossy(LiteralType::U32).unwrap();

    // Get the bits of the number.
    let bits = match number {
        Literal::U32(number) => number.to_bits_le(),
        _ => panic!("expected u32")
    };

    // Print the records.
    for record in records {
        print!("\"{}\" ", record);
    }

    // Print the bits, formatted in the appropriate struct.
    let mut bit_struct = "{".to_string();
    for (i, bit) in bits.iter().enumerate() {
        bit_struct.push_str(&format!("\n  b{}: {},", i, bit));
    }
    bit_struct.push_str("\n}");
    println!("\"{bit_struct}\"\n");

    // Print the number for reference.
    println!("\n\n\"{}\"", number);

    // Print the seed for reference.
    println!("\n\n\"{}\"", aggregate_seed);





}
