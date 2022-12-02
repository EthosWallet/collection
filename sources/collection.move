module collection::collection {
    use std::option::{Self, Option};
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer::{Self};
    use sui::object_table::{Self, ObjectTable};
    use capy::capy::Capy;

    const EVoterObjectDNE: u64 = 1;
    const EVoterObjectAlreadyExists: u64 = 2;
    const EAdminCapDNE: u64 = 3;

    // ================ Election ================

    struct ElectionAdminCap has key, store { id: UID }

    struct Election has key {
        id: UID,
        cycle: u64,
        /// There's currently no way to traverse a table like a linked list so a u64 is used as the key
        candidates: ObjectTable<u64, Candidate>
    }

    struct PastWinners has key {
        id: UID,
        winners: ObjectTable<u64, Candidate>
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(ElectionAdminCap { id: object::new(ctx) }, tx_context::sender(ctx));

        transfer::share_object(Election {
            id: object::new(ctx),
            cycle: 0,
            candidates: object_table::new<u64, Candidate>(ctx)
        });

        transfer::transfer(PastWinners {
            id: object::new(ctx),
            winners: object_table::new<u64, Candidate>(ctx)
        }, tx_context::sender(ctx));
    }

    entry fun end_election(
        _: &ElectionAdminCap,
        election: &mut Election,
        past_winners: &mut PastWinners,
    ) {
        // Find the candidate with the greatest number of votes (the `winner`)
        let candidate_table = &mut election.candidates;
        let current_index = 0;
        let winner_index = 0;
        let max_votes = 0;
        while (current_index < object_table::length(candidate_table)) {
            let current_candidate = object_table::borrow(candidate_table, current_index);
            if (current_candidate.votes > max_votes) {
                max_votes = current_candidate.votes;
                winner_index = copy current_index;
                current_index = current_index + 1;
            } else current_index = current_index + 1;
        };
        let winner = object_table::remove(candidate_table, winner_index);

        // Move the winner to the PastWinners' object
        let past_winners_table = &mut past_winners.winners;
        object_table::add(past_winners_table, election.cycle, winner);

        // Update the cycle for the next election
        election.cycle = election.cycle + 1;
    }

    entry fun new_election(
        _: &ElectionAdminCap,
        election: &mut Election,
        ctx: &mut TxContext
    ) {
        let current_cycle = election.cycle;

        transfer::share_object(Election {
            id: object::new(ctx),
            cycle: current_cycle,
            candidates: object_table::new<u64, Candidate>(ctx)
        });
    }

    // ================ Candidate ================

    /// A Capy selected to be voted on
    struct Candidate has store, key {
        id: UID,
        /// ID of the Capy a user wants to nominate
        capy_id: ID,
        /// User that nominated the candidate
        nominator: address,
        /// The election cycle a particular candidate belongs to
        cycle: u64,
        /// Total number of votes
        votes: u64,
        /// The index of the candidate in the candidates' ObjectTable in the `Election` object
        index: u64
    }

    public entry fun nominate(
        election: &mut Election,
        capy: &Capy,
        ctx: &mut TxContext
    ) {
        let capy_id = capy_id_from_capy(capy);
        // Add the candidate to the table
        let candidate_table = &mut election.candidates;
        // The key (index) of the newest candidate is equal to the current length of the table
        let key = object_table::length(candidate_table);
        let new_candidate = Candidate {
            id: object::new(ctx),
            capy_id,
            nominator: tx_context::sender(ctx),
            cycle: election.cycle,
            votes: 0,
            index: key
        };
        object_table::add(candidate_table, key, new_candidate);
    }

    public fun nominator(candidate: &Candidate): address {
        candidate.nominator
    }

    public fun cycle(candidate: &Candidate): u64 {
        candidate.cycle
    }

    public fun votes_from_candidate(candidate: &Candidate): u64 {
        candidate.votes
    }

    public fun votes_from_election(election: &Election, index: u64): u64 {
        let candidate_table = &election.candidates;
        let candidate = object_table::borrow(candidate_table, index);
        candidate.votes
    }

    public fun index(candidate: &Candidate): u64 {
        candidate.index
    }

    public fun capy_id_from_candidate(candidate: &Candidate): ID {
        candidate.capy_id
    }

    public fun capy_id_from_capy(capy: &Capy): ID {
        object::id(capy)
    }

    // ================ Voter ================

    /// A voter object allowing an address to vote on only one entry per election cycle
    struct Voter has store, key {
        id: UID,
        cycle: u64,
        has_voted: bool,
        voted_for: Option<u64>
    }

    public entry fun register(
        election: &Election,
        ctx: &mut TxContext
    ) {
        transfer::transfer(Voter {
            id: object::new(ctx),
            cycle: election.cycle,
            has_voted: false,
            voted_for: option::none<u64>()
        }, tx_context::sender(ctx));
    }

    public entry fun vote(
        election: &mut Election,
        voter: &mut Voter,
        candidate_index: u64,
    ) {
        // Find the candidate and increment their total votes by 1
        let candidate_table = &mut election.candidates;
        let candidate = object_table::borrow_mut(candidate_table, copy candidate_index);
        candidate.votes = candidate.votes + 1;

        // Update the Voter struct to reflect a users' vote
        voter.has_voted = true;
        option::fill<u64>(&mut voter.voted_for, candidate_index);
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        transfer::transfer(ElectionAdminCap { id: object::new(ctx) }, tx_context::sender(ctx));

        transfer::share_object(Election {
            id: object::new(ctx),
            cycle: 0,
            candidates: object_table::new<u64, Candidate>(ctx)
        });

        transfer::transfer(PastWinners {
            id: object::new(ctx),
            winners: object_table::new<u64, Candidate>(ctx)
        }, tx_context::sender(ctx));
    }

    #[test_only]
    public fun end_election_for_test(
        _: &ElectionAdminCap,
        election: &mut Election,
        past_winners: &mut PastWinners,
    ) {
        // Find the candidate with the greatest number of votes (the `winner`)
        let candidate_table = &mut election.candidates;
        let current_index = 0;
        let winner_index = 0;
        let max_votes = 0;
        while (current_index < object_table::length(candidate_table)) {
            let current_candidate = object_table::borrow(candidate_table, current_index);
            if (current_candidate.votes > max_votes) {
                max_votes = current_candidate.votes;
                winner_index = copy current_index;
                current_index = current_index + 1;
            } else current_index = current_index + 1;
        };
        let winner = object_table::remove(candidate_table, winner_index);

        // Move the winner to the PastWinners' object
        let past_winners_table = &mut past_winners.winners;
        object_table::add(past_winners_table, election.cycle, winner);

        // Update the cycle for the next election
        election.cycle = election.cycle + 1;
    }

    #[test_only]
    public fun new_election_for_test(
        _: &ElectionAdminCap,
        election: &mut Election,
        ctx: &mut TxContext
    ) {
        let current_cycle = election.cycle;

        transfer::share_object(Election {
            id: object::new(ctx),
            cycle: current_cycle,
            candidates: object_table::new<u64, Candidate>(ctx)
        });
    }

    #[test_only]
    public fun is_past_winners_empty(past_winners: &PastWinners): bool {
        let winners = &past_winners.winners;
        object_table::is_empty(winners)
    }
}