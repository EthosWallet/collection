#[test_only]
module collection::collection_tests {
    use sui::test_scenario::{Self, Scenario};
    use collection::collection::{Self, Election, Voter};
    use capy::capy::Capy;

    const ADMIN: address = @0x123;
    const VOTER: address = @0x234;

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
            let election_object = test_scenario::take_shared<Election>(&mut scenario);
            register_for_test(&mut election_object, &mut scenario);
            test_scenario::return_shared(election_object);
        };

        test_scenario::end(scenario);
    }

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
