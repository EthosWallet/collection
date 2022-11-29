#[test_only]
module collection::collection_tests {
    use sui::test_scenario::{Self, Scenario};
    use collection::collection::{Self, Election, Voter};
    use capy::capy::{Self, Capy, CapyManagerCap, CapyRegistry};
    use sui::transfer;

    const ADMIN: address = @0x123;
    const VOTER: address = @0x234;
    const NOMINATOR: address = @0x345;

    // ================ Tests ================

    #[test]
    fun test_init() {
        let scenario = test_scenario::begin(ADMIN);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            collection::init_for_test(ctx)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_init_register() {
        let scenario = test_scenario::begin(ADMIN);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            collection::init_for_test(ctx)
        };

        test_scenario::next_tx(&mut scenario, VOTER);
        {
            let election = test_scenario::take_shared<Election>(&mut scenario);
            register_for_test(&mut election, &mut scenario);
            test_scenario::return_shared(election);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_batch_capy() {
        let scenario = test_scenario::begin(ADMIN);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            capy::init_for_test(ctx);
        };

        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let capy_manager_cap = test_scenario::take_from_sender<CapyManagerCap>(&mut scenario);
            let reg = test_scenario::take_shared<CapyRegistry>(&mut scenario);
            capy::batch_for_test(&capy_manager_cap, &mut reg, &mut scenario);
            test_scenario::return_to_sender(&scenario, capy_manager_cap);
            test_scenario::return_shared(reg);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_e2e() {
        // First tx: init collection and capys
        let scenario = test_scenario::begin(ADMIN);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            collection::init_for_test(ctx);
            capy::init_for_test(ctx);
        };

        // Second tx: register voter
        test_scenario::next_tx(&mut scenario, VOTER);
        {
            let election = test_scenario::take_shared<Election>(&mut scenario);
            register_for_test(&mut election, &mut scenario);
            test_scenario::return_shared(election);
        };

        // Third tx: create capy via `batch`
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let capy_manager_cap = test_scenario::take_from_sender<CapyManagerCap>(&mut scenario);
            let reg = test_scenario::take_shared<CapyRegistry>(&mut scenario);
            capy::batch_for_test(&capy_manager_cap, &mut reg, &mut scenario);
            test_scenario::return_to_sender(&scenario, capy_manager_cap);
            test_scenario::return_shared(reg);
        };

        // Fourth tx: nominate capy
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let election = test_scenario::take_shared<Election>(&mut scenario);
            let capy = test_scenario::take_from_sender<Capy>(&mut scenario);
            nominate_for_test(&mut election, &capy, &mut scenario);
            test_scenario::return_shared(election);
            test_scenario::return_to_sender(&scenario, capy);
        };

        // Fifth tx: vote on capy
        test_scenario::next_tx(&mut scenario, VOTER);
        {
            let election = test_scenario::take_shared<Election>(&mut scenario);
            let voter = test_scenario::take_from_sender<Voter>(&mut scenario);
            vote_for_test(&mut election, &mut voter, 0);

            // Check that the capy has 1 vote
            let capy_votes = collection::votes_from_election(&election, 0);
            assert!(capy_votes == 1, 0);
            test_scenario::return_shared(election);
            test_scenario::return_to_sender(&scenario, voter);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_e2e_two_capys() {
        // First tx: init collection and capys
        let scenario = test_scenario::begin(ADMIN);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            collection::init_for_test(ctx);
            capy::init_for_test(ctx);
        };

        // Second tx: register voter
        test_scenario::next_tx(&mut scenario, VOTER);
        {
            let election = test_scenario::take_shared<Election>(&mut scenario);
            register_for_test(&mut election, &mut scenario);
            test_scenario::return_shared(election);
        };

        // Third tx: create capy via `batch`
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let capy_manager_cap = test_scenario::take_from_sender<CapyManagerCap>(&mut scenario);
            let reg = test_scenario::take_shared<CapyRegistry>(&mut scenario);
            capy::batch_for_test(&capy_manager_cap, &mut reg, &mut scenario);
            test_scenario::return_to_sender(&scenario, capy_manager_cap);
            test_scenario::return_shared(reg);
        };

        // Fourth tx: create another capy via `batch`
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let capy_manager_cap = test_scenario::take_from_sender<CapyManagerCap>(&mut scenario);
            let reg = test_scenario::take_shared<CapyRegistry>(&mut scenario);
            capy::batch_for_test(&capy_manager_cap, &mut reg, &mut scenario);
            test_scenario::return_to_sender(&scenario, capy_manager_cap);
            test_scenario::return_shared(reg);
        };

        // Fifth tx: send a capy to `NOMINATOR`
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let capy = test_scenario::take_from_sender<Capy>(&mut scenario);
            transfer::transfer(capy, NOMINATOR);
        };

        // Sixth tx: have `ADMIN` nominate a capy
        test_scenario::next_tx(&mut scenario, ADMIN);
        {

        };

        // Seventh tx: have `NOMINATOR` nominate a capy
        {

        };

        // Eighth tx: have `VOTER` vote for `ADMIN`'s capy (id: 0)
        {

        };

        // Ninth tx: register `NOMINATOR` as a voter
        {

        };

        // Tenth tx: have `NOMINATOR` vote for their own capy (id: 1)
        {

        };
        test_scenario::end(scenario);
    }

    // ================ Expected Failures ================

    #[test]
    #[expected_failure]
    fun test_vote_on_capy_outside_of_range() {
        // First tx: init collection and capys
        let scenario = test_scenario::begin(ADMIN);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            collection::init_for_test(ctx);
            capy::init_for_test(ctx);
        };

        // Second tx: register voter
        test_scenario::next_tx(&mut scenario, VOTER);
        {
            let election = test_scenario::take_shared<Election>(&mut scenario);
            register_for_test(&mut election, &mut scenario);
            test_scenario::return_shared(election);
        };

        // Third tx: create capys via `batch`
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let capy_manager_cap = test_scenario::take_from_sender<CapyManagerCap>(&mut scenario);
            let reg = test_scenario::take_shared<CapyRegistry>(&mut scenario);
            capy::batch_for_test(&capy_manager_cap, &mut reg, &mut scenario);
            test_scenario::return_to_sender(&scenario, capy_manager_cap);
            test_scenario::return_shared(reg);
        };

        // Fourth tx: nominate capy
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let election = test_scenario::take_shared<Election>(&mut scenario);
            let capy = test_scenario::take_from_sender<Capy>(&mut scenario);
            nominate_for_test(&mut election, &capy, &mut scenario);
            test_scenario::return_shared(election);
            test_scenario::return_to_sender(&scenario, capy);
        };

        // Fifth tx: vote on capy
        test_scenario::next_tx(&mut scenario, VOTER);
        {
            let election = test_scenario::take_shared<Election>(&mut scenario);
            let voter = test_scenario::take_from_sender<Voter>(&mut scenario);
            // There is only 1 capy nominated, so the only valid capy id is 0
            vote_for_test(&mut election, &mut voter, 1);
            test_scenario::return_shared(election);
            test_scenario::return_to_sender(&scenario, voter);
        };

        test_scenario::end(scenario);
    }

    // ================ Test-Only Functions ================

    fun nominate_for_test(
        election: &mut Election,
        capy: &Capy,
        scenario: &mut Scenario
    ) {
        let ctx = test_scenario::ctx(scenario);
        collection::nominate(election, capy, ctx)
    }

    fun register_for_test(
        election: &mut Election,
        scenario: &mut Scenario
    ) {
        let ctx = test_scenario::ctx(scenario);
        collection::register(election, ctx);
    }

    fun vote_for_test(
        election: &mut Election,
        voter: &mut Voter,
        candidate_index: u64
    ) {
        collection::vote(election, voter, candidate_index);
    }
}
