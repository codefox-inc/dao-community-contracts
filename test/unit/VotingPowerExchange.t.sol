// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract VotingPowerExchangeUnitTest is Test {
    VotingPowerExchange public votingPowerExchange;

    function setUp() public {
        // We need to deploy VotingPowerExchange
        votingPowerExchange =
            new VotingPowerExchange(address(this), address(this), address(this), address(this), address(this));
    }

    function testSpecialCasesForCalculateVotingPowerFromBurnedAmount() public view {
        // test case 1: 1950 * 1e18 -> 15 * 1e18
        uint256 amount1 = 1950 * 1e18;
        uint256 expectedVotingPower1 = 15 * 1e18;
        uint256 actualVotingPower1 = votingPowerExchange.calculateVotingPowerFromBurnedAmount(amount1);

        // assertApproxEqRel(actualVotingPower1, expectedVotingPower1, 0.001e18);
        assertEq(actualVotingPower1, expectedVotingPower1);

        // test case 2: 0 -> 0
        uint256 amount2 = 0;
        uint256 expectedVotingPower2 = 0;
        uint256 actualVotingPower2 = votingPowerExchange.calculateVotingPowerFromBurnedAmount(amount2);
        assertEq(actualVotingPower2, expectedVotingPower2);

        // test case 3: 3350 * 1e18 -> 20 * 1e18
        uint256 amount3 = 3350 * 1e18;
        uint256 expectedVotingPower3 = 20 * 1e18;
        uint256 actualVotingPower3 = votingPowerExchange.calculateVotingPowerFromBurnedAmount(amount3);
        // assertApproxEqRel(actualVotingPower3, expectedVotingPower3, 0.001e18);
        assertEq(actualVotingPower3, expectedVotingPower3);
    }

    function testSomeMoreSpecialCasesForCalculateVotingPowerFromBurnedAmount() public view {
        // test case 4: 20 * 1e18 -> approximately 1.840 * 1e18
        uint256 amount4 = 20 * 1e18;
        uint256 expectedVotingPower4 = 0.84026 * 1e18;
        uint256 actualVotingPower4 = votingPowerExchange.calculateVotingPowerFromBurnedAmount(amount4);
        assertApproxEqRel(actualVotingPower4, expectedVotingPower4, 0.001e16);

        // test case 5: 15092 * 1e18 -> 44.70679 * 1e18
        uint256 amount5 = 15092 * 1e18;
        uint256 expectedVotingPower5 = 43.70679 * 1e18;
        uint256 actualVotingPower5 = votingPowerExchange.calculateVotingPowerFromBurnedAmount(amount5);
        assertApproxEqRel(actualVotingPower5, expectedVotingPower5, 0.001e16);

        // test case 6: 11_442 * 1e18 -> 37.9096 * 1e18
        uint256 amount6 = 11_442 * 1e18;
        uint256 expectedVotingPower6 = 37.9096 * 1e18;
        uint256 actualVotingPower6 = votingPowerExchange.calculateVotingPowerFromBurnedAmount(amount6);
        assertApproxEqRel(actualVotingPower6, expectedVotingPower6, 0.001e16);
    }

    function testCalculateVotingPowerFromBurnedAmount() public view {
        uint256[100] memory burnedAmounts = [
            uint256(0),
            uint256(25),
            uint256(65),
            uint256(120),
            uint256(190),
            uint256(275),
            uint256(375),
            uint256(490),
            uint256(620),
            uint256(765),
            uint256(925),
            uint256(1100),
            uint256(1290),
            uint256(1495),
            uint256(1715),
            uint256(1950),
            uint256(2200),
            uint256(2465),
            uint256(2745),
            uint256(3040),
            uint256(3350),
            uint256(3675),
            uint256(4015),
            uint256(4370),
            uint256(4740),
            uint256(5125),
            uint256(5525),
            uint256(5940),
            uint256(6370),
            uint256(6815),
            uint256(7275),
            uint256(7750),
            uint256(8240),
            uint256(8745),
            uint256(9265),
            uint256(9800),
            uint256(10350),
            uint256(10915),
            uint256(11495),
            uint256(12090),
            uint256(12700),
            uint256(13325),
            uint256(13965),
            uint256(14620),
            uint256(15290),
            uint256(15975),
            uint256(16675),
            uint256(17390),
            uint256(18120),
            uint256(18865),
            uint256(19625),
            uint256(20400),
            uint256(21190),
            uint256(21995),
            uint256(22815),
            uint256(23650),
            uint256(24500),
            uint256(25365),
            uint256(26245),
            uint256(27140),
            uint256(28050),
            uint256(28975),
            uint256(29915),
            uint256(30870),
            uint256(31840),
            uint256(32825),
            uint256(33825),
            uint256(34840),
            uint256(35870),
            uint256(36915),
            uint256(37975),
            uint256(39050),
            uint256(40140),
            uint256(41245),
            uint256(42365),
            uint256(43500),
            uint256(44650),
            uint256(45815),
            uint256(46995),
            uint256(48190),
            uint256(49400),
            uint256(50625),
            uint256(51865),
            uint256(53120),
            uint256(54390),
            uint256(55675),
            uint256(56975),
            uint256(58290),
            uint256(59620),
            uint256(60965),
            uint256(62325),
            uint256(63700),
            uint256(65090),
            uint256(66495),
            uint256(67915),
            uint256(69350),
            uint256(70800),
            uint256(72265),
            uint256(73745),
            uint256(75240)
        ];

        uint256[100] memory expectedVotingPowers = [
            uint256(0),
            uint256(1),
            uint256(2),
            uint256(3),
            uint256(4),
            uint256(5),
            uint256(6),
            uint256(7),
            uint256(8),
            uint256(9),
            uint256(10),
            uint256(11),
            uint256(12),
            uint256(13),
            uint256(14),
            uint256(15),
            uint256(16),
            uint256(17),
            uint256(18),
            uint256(19),
            uint256(20),
            uint256(21),
            uint256(22),
            uint256(23),
            uint256(24),
            uint256(25),
            uint256(26),
            uint256(27),
            uint256(28),
            uint256(29),
            uint256(30),
            uint256(31),
            uint256(32),
            uint256(33),
            uint256(34),
            uint256(35),
            uint256(36),
            uint256(37),
            uint256(38),
            uint256(39),
            uint256(40),
            uint256(41),
            uint256(42),
            uint256(43),
            uint256(44),
            uint256(45),
            uint256(46),
            uint256(47),
            uint256(48),
            uint256(49),
            uint256(50),
            uint256(51),
            uint256(52),
            uint256(53),
            uint256(54),
            uint256(55),
            uint256(56),
            uint256(57),
            uint256(58),
            uint256(59),
            uint256(60),
            uint256(61),
            uint256(62),
            uint256(63),
            uint256(64),
            uint256(65),
            uint256(66),
            uint256(67),
            uint256(68),
            uint256(69),
            uint256(70),
            uint256(71),
            uint256(72),
            uint256(73),
            uint256(74),
            uint256(75),
            uint256(76),
            uint256(77),
            uint256(78),
            uint256(79),
            uint256(80),
            uint256(81),
            uint256(82),
            uint256(83),
            uint256(84),
            uint256(85),
            uint256(86),
            uint256(87),
            uint256(88),
            uint256(89),
            uint256(90),
            uint256(91),
            uint256(92),
            uint256(93),
            uint256(94),
            uint256(95),
            uint256(96),
            uint256(97),
            uint256(98),
            uint256(99)
        ];

        for (uint256 i = 0; i < burnedAmounts.length; i++) {
            uint256 amount = burnedAmounts[i] * 1e18;
            uint256 expectedVotingPower = expectedVotingPowers[i] * 1e18;
            uint256 actualVotingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(amount);

            assertEq(
                actualVotingPower,
                expectedVotingPower,
                string(abi.encodePacked("Test case failed for burned amount: ", Strings.toString(burnedAmounts[i])))
            );
        }
    }

    function testCalculateIncrementedVotingPower() public view {
        // Test case 1: Starting from 0 burned amount
        // Burning 3350 tokens should result in 20 voting power
        runTestCase(3350 * 1e18, 0, 20 * 1e18, 1);

        // Test case 2: Incremental increase from existing burned amount
        // Burning additional 1400 tokens from 1950 should increase voting power by 5
        runTestCase(1400 * 1e18, 1950 * 1e18, 5 * 1e18, 2);

        // Test case 3: Large incremental increase
        // Burning additional 11375 tokens from 16675 should increase voting power by 14
        runTestCase(11375 * 1e18, 16675 * 1e18, 14 * 1e18, 3);

        // Test case 4: Minimum threshold for voting power increase
        // Burning 25 tokens from 0 should result in 1 voting power
        runTestCase(25 * 1e18, 0, 1 * 1e18, 4);

        // Test case 5: Zero token burn
        // Burning 0 tokens should not increase voting power
        runTestCase(0, 10000 * 1e18, 0, 5);

        // Test case 6: Small incremental increase
        // Burning 740 tokens from 25 should increase voting power by 8
        runTestCase(740 * 1e18, 25 * 1e18, 8 * 1e18, 6);

        // Test case 7: Medium incremental increase
        // Burning 2920 tokens from 120 should increase voting power by 16
        runTestCase(2920 * 1e18, 120 * 1e18, 16 * 1e18, 7);

        // Test case 8: Large incremental increase
        // Burning 6695 tokens from 120 should increase voting power by 26
        runTestCase(6695 * 1e18, 120 * 1e18, 26 * 1e18, 8);

        // Test case 9: Very large incremental increase
        // Burning 11970 tokens from 120 should increase voting power by 36
        runTestCase(11970 * 1e18, 120 * 1e18, 36 * 1e18, 9);

        // Test case 10: Extreme large incremental increase
        // Burning 18745 tokens from 120 should increase voting power by 46
        runTestCase(18745 * 1e18, 120 * 1e18, 46 * 1e18, 10);

        // Test case 11: Extreme large incremental increase
        // Burning 18745 tokens from 120 should increase voting power by 99
        runTestCase(75240 * 1e18, 0 * 1e18, 99 * 1e18, 11);

        // Test case 12: Extreme large incremental increase
        // Burning 75215 tokens from 25 should increase voting power by 98
        runTestCase(75215 * 1e18, 25 * 1e18, 98 * 1e18, 12);
    }

    // Helper function to run individual test cases
    // Parameters:
    // - amount: The amount of tokens to be burned
    // - currentBurnedAmount: The amount of tokens already burned
    // - expectedIncrease: The expected increase in voting power
    // - testCaseNumber: The number of the test case for easy identification
    function runTestCase(uint256 amount, uint256 currentBurnedAmount, uint256 expectedIncrease, uint256 testCaseNumber)
        internal
        view
    {
        uint256 actualIncrease = votingPowerExchange.calculateIncrementedVotingPower(amount, currentBurnedAmount);
        assertEq(
            actualIncrease,
            expectedIncrease,
            string(abi.encodePacked("Test case ", Strings.toString(testCaseNumber), " failed"))
        );
    }
}
