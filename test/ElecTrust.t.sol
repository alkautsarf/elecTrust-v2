// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {ElecTrust} from "../src/ElecTrust.sol";

contract ElecTrustTest is Test {
    ElecTrust public elecTrust;

    string public constant ELECTION_NAME = "ElecTrust";
    uint256 public constant DURATION = 1 days;

    address[] public voters;
    string[] public candidates = ["Alice", "Bob", "Charlie"];
    uint256 public votersIndex = 5;

    event ElectionCreated(string electionName, uint256 indexed totalCandidates);
    event Voted(address indexed voter, uint256 indexed elections, uint256 indexed candidateBeingVoted);

    function setUp() public {
        elecTrust = new ElecTrust();
        for (uint256 i = 1; i <= votersIndex;) {
            voters.push(address(uint160(i)));
            unchecked {
                ++i;
            }
        }
    }

    //* @notice Create an election

    modifier createElection() {
        address[] memory _voters;
        elecTrust.createElection(ELECTION_NAME, candidates, _voters, DURATION);
        _;
    }

    modifier createElectionStrictVoters() {
        elecTrust.createElection(ELECTION_NAME, candidates, voters, DURATION);
        _;
    }

    function test_create_election() public {
        vm.expectEmit(false, true, false, false);
        emit ElectionCreated(ELECTION_NAME, candidates.length);

        address[] memory _voters;
        elecTrust.createElection(ELECTION_NAME, candidates, _voters, DURATION);
    }

    function test_revert_create_election_invalid_name() public {
        vm.expectRevert(ElecTrust.InvalidName.selector);
        elecTrust.createElection("", candidates, voters, DURATION);
    }

    function test_revert_create_election_invalid_candidates() public {
        string[] memory _candidates;
        vm.expectRevert(ElecTrust.InvalidCandidateIndex.selector);
        elecTrust.createElection(ELECTION_NAME, _candidates, voters, DURATION);
    }

    //* @notice Vote for a candidate

    function test_revert_vote_voting_end() public createElection {
        vm.warp(block.timestamp + DURATION + 1);
        vm.expectRevert(ElecTrust.VotingEnd.selector);
        elecTrust.vote(0, 0);
    }

    function test_revert_unauthorized_voter() public createElectionStrictVoters {
        vm.expectRevert(ElecTrust.UnauthorizedVoter.selector);
        elecTrust.vote(0, 0);
    }

    function test_revert_has_voted() public createElection {
        elecTrust.vote(0, 0);
        vm.expectRevert(ElecTrust.HasVoted.selector);
        elecTrust.vote(0, 0);
    }

    function test_vote_non_strict() public createElection {
        vm.expectEmit(true, true, true, true);
        emit Voted(address(this), 0, 0);
        elecTrust.vote(0, 0);
    }

    function test_vote_strict_voters() public createElectionStrictVoters {
        vm.startPrank(voters[0]);
        (, uint256 voteCountBefore) = elecTrust.getCandidate(0, 0);
        elecTrust.vote(0, 0);
        (, uint256 voteCountAfter) = elecTrust.getCandidate(0, 0);
        vm.stopPrank();
        assertEq(elecTrust.getHasVoted(0, voters[0]), true);
        assertEq(voteCountAfter, voteCountBefore + 1);
    }

    //* @notice Get election info

    function test_get_election_info() public createElection {
        (string memory name, uint256 startTime, uint256 duration, uint256 totalCandidates) =
            elecTrust.getElectionInfo(0);
        assertEq(name, ELECTION_NAME);
        assertEq(startTime, block.timestamp);
        assertEq(duration, DURATION);
        assertEq(totalCandidates, candidates.length);
    }

    function test_get_candidate_info() public createElection {
        (string memory name, uint256 voteCount) = elecTrust.getCandidate(0, 0);
        assertEq(name, candidates[0]);
        assertEq(voteCount, 0);
    }

    function test_get_has_voted() public createElection {
        assertEq(elecTrust.getHasVoted(0, voters[0]), false);
    }

    function test_get_number_of_running_elections() public createElection createElectionStrictVoters {
        assertEq(elecTrust.getNumberOfElections(), 2);
    }
}
