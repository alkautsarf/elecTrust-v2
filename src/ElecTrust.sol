// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title ElecTrust
 * @author elpabl0.eth
 * @notice A smart contract for conducting elections.
 */
contract ElecTrust {
    // Struct to represent a candidate
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    // Struct to represent an election
    struct Election {
        string electionName;
        uint256 startTime;
        uint256 duration;
        uint256 totalCandidates;
        mapping(uint256 => Candidate) candidates;
        mapping(address => bool) hasVoted;
        mapping(address => bool) voters;
        bool strictVoters;
    }

    // Array to store all elections
    Election[] private elections;

    // Error definitions
    error InvalidName();
    error InvalidCandidateName();
    error InvalidCandidateIndex();
    error HasVoted();
    error VotingEnd();
    error UnauthorizedVoter();
    error ElectionNotFound();
    error CandidateNotFound();

    // Event emitted when an election is created
    event ElectionCreated(string electionName, uint256 indexed totalCandidates, bool strictVoters);
    event Voted(address indexed voter, string elections, string candidateBeingVoted);

    modifier checkValidElection(uint256 electionIndex) {
        if (electionIndex >= getNumberOfElections()) revert ElectionNotFound();
        _;
    }

    modifier checkValidElectionAndCandidate(uint256 electionIndex, uint256 candidateIndex) {
        if (electionIndex >= getNumberOfElections()) revert ElectionNotFound();
        if (candidateIndex > elections[electionIndex].totalCandidates || candidateIndex == 0) {
            revert CandidateNotFound();
        }
        _;
    }

    /**
     * @notice Creates a new election.
     * @param name The name of the election.
     * @param candidates The names of the candidates.
     * @param voters The addresses of the eligible voters.
     * @param duration The duration of the election in seconds.
     */
    function createElection(
        string calldata name,
        string[] calldata candidates,
        address[] calldata voters,
        uint256 duration
    ) external {
        if (!_checkLen(name)) revert InvalidName();
        if (candidates.length == 0) revert InvalidCandidateIndex();
        Election storage _election = elections.push();
        for (uint256 i = 1; i <= candidates.length;) {
            if (!_checkLen(candidates[i - 1])) revert InvalidCandidateName();
            _election.candidates[i].name = candidates[i - 1];
            unchecked {
                ++i;
            }
        }
        if (voters.length == 0) {
            _election.strictVoters = false;
        } else {
            _election.strictVoters = true;
            for (uint256 i = 0; i < voters.length;) {
                _election.voters[voters[i]] = true;
                unchecked {
                    ++i;
                }
            }
        }
        _election.electionName = name;
        _election.startTime = block.timestamp;
        _election.duration = duration;
        _election.totalCandidates = candidates.length;
        emit ElectionCreated(name, candidates.length, _election.strictVoters);
    }

    /**
     * @notice Casts a vote for a candidate in an election.
     * @param electionIndex The index of the election.
     * @param candidateIndex The index of the candidate to vote for.
     */
    function vote(uint256 electionIndex, uint256 candidateIndex)
        external
        checkValidElectionAndCandidate(electionIndex, candidateIndex)
    {
        if (elections[electionIndex].hasVoted[msg.sender]) revert HasVoted();
        if (block.timestamp > elections[electionIndex].startTime + elections[electionIndex].duration) {
            revert VotingEnd();
        }
        if (!elections[electionIndex].strictVoters) {
            elections[electionIndex].hasVoted[msg.sender] = true;
            elections[electionIndex].candidates[candidateIndex].voteCount += 1;
        } else {
            if (elections[electionIndex].voters[msg.sender]) {
                elections[electionIndex].hasVoted[msg.sender] = true;
                elections[electionIndex].candidates[candidateIndex].voteCount += 1;
            } else {
                revert UnauthorizedVoter();
            }
        }
        emit Voted(
            msg.sender, elections[electionIndex].electionName, elections[electionIndex].candidates[candidateIndex].name
        );
    }

    /**
     * @notice Retrieves information about an election.
     * @param electionIndex The index of the election.
     * @return The name, start time, duration, total candidates, and strict voters state.
     */
    function getElectionInfo(uint256 electionIndex)
        external
        view
        checkValidElection(electionIndex)
        returns (string memory, uint256, uint256, uint256, bool)
    {
        Election storage election = elections[electionIndex];
        return (
            election.electionName,
            election.startTime,
            election.duration,
            election.totalCandidates,
            election.strictVoters
        );
    }

    /**
     * @notice Retrieves information about a candidate in an election.
     * @param electionIndex The index of the election.
     * @param candidateIndex The index of the candidate.
     * @return The name and vote count of the candidate.
     */
    function getCandidate(uint256 electionIndex, uint256 candidateIndex)
        external
        view
        checkValidElectionAndCandidate(electionIndex, candidateIndex)
        returns (string memory, uint256)
    {
        Candidate storage candidate = elections[electionIndex].candidates[candidateIndex];
        return (candidate.name, candidate.voteCount);
    }

    /**
     * @notice Checks if a voter has voted in an election.
     * @param electionIndex The index of the election.
     * @param voter The address of the voter.
     * @return A boolean indicating whether the voter has voted.
     */
    function getHasVoted(uint256 electionIndex, address voter) external view checkValidElection(electionIndex) returns (bool) {
        return elections[electionIndex].hasVoted[voter];
    }

    /**
     * @notice Returns the number of elections.
     * @return The number of elections as a uint256 value.
     */
    function getNumberOfElections() public view returns (uint256) {
        return elections.length;
    }

    /**
     * @notice Checks if the length of a string is non-zero.
     * @param name The string to check.
     * @return A boolean indicating whether the length of the string is non-zero.
     */
    function _checkLen(string memory name) private pure returns (bool) {
        bytes memory _bytesName = bytes(name);
        return _bytesName.length != 0 ? true : false;
    }
}
