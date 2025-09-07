import { describe, it, expect, beforeEach } from "vitest";

const ERR_NOT_AUTHORIZED = 100;
const ERR_INVALID_PROJECT_ID = 101;
const ERR_INVALID_ADDRESS = 102;
const ERR_INVALID_DESCRIPTION = 103;
const ERR_INVALID_MILESTONE = 104;
const ERR_INVALID_AMOUNT = 105;
const ERR_PROJECT_ALREADY_EXISTS = 106;
const ERR_PROJECT_NOT_FOUND = 107;
const ERR_INSUFFICIENT_FUNDS = 108;
const ERR_MILESTONE_NOT_ACHIEVED = 109;
const ERR_DISTRIBUTION_ALREADY_APPROVED = 110;
const ERR_DISTRIBUTION_NOT_APPROVED = 111;
const ERR_INVALID_VOTE = 112;
const ERR_VOTING_PERIOD_ENDED = 113;
const ERR_VOTING_PERIOD_ACTIVE = 114;
const ERR_MAX_PROJECTS_EXCEEDED = 115;
const ERR_INVALID_TIMESTAMP = 116;
const ERR_INVALID_PERCENTAGE = 117;
const ERR_ALLOCATION_EXCEEDED = 118;
const ERR_INVALID_STATUS = 119;
const ERR_LOGGING_FAILED = 120;
const ERR_GOVERNANCE_NOT_VERIFIED = 121;
const ERR_ESCROW_NOT_VERIFIED = 122;
const ERR_INVALID_PROPOSAL_ID = 123;
const ERR_PROPOSAL_NOT_FOUND = 124;
const ERR_PROPOSAL_ALREADY_EXECUTED = 125;

interface Milestone {
  description: string;
  achieved: boolean;
  amount: number;
}

interface Project {
  recipient: string;
  description: string;
  totalAllocated: number;
  totalReleased: number;
  milestones: Milestone[];
  status: string;
  registrationTimestamp: number;
}

interface Proposal {
  projectId: number;
  amount: number;
  proposer: string;
  votesFor: number;
  votesAgainst: number;
  startBlock: number;
  endBlock: number;
  executed: boolean;
}

class FundDistributorMock {
  state!: {
    admin: string;
    nextProjectId: number;
    nextProposalId: number;
    maxProjects: number;
    votingPeriod: number;
    governanceContract: string;
    escrowContract: string;
    auditLoggerContract: string;
    projects: Map<number, Project>;
    proposals: Map<number, Proposal>;
    votes: Map<string, boolean>;
    fundsBalance: Map<string, number>;
  };
  blockHeight = 0;
  caller = "ST1ADMIN";
  balances: Map<string, number> = new Map();
  eligibleVoters: Set<string> = new Set();
  loggedEvents: Array<{ event: string; id: number | null; sender: string; height: number }> = [];

  constructor() {
    this.reset();
  }

  reset() {
    this.state = {
      admin: this.caller,
      nextProjectId: 1,
      nextProposalId: 1,
      maxProjects: 500,
      votingPeriod: 144,
      governanceContract: "SP000000000000000000002Q6VF78.governance-dao",
      escrowContract: "SP000000000000000000002Q6VF78.escrow-vault",
      auditLoggerContract: "SP000000000000000000002Q6VF78.audit-logger",
      projects: new Map(),
      proposals: new Map(),
      votes: new Map(),
      fundsBalance: new Map(),
    };
    this.blockHeight = 0;
    this.caller = "ST1ADMIN";
    this.balances.set(this.caller, 1000000);
    this.eligibleVoters.add(this.caller);
    this.loggedEvents = [];
  }

  isEligibleVoter(voter: string): boolean {
    return this.eligibleVoter

s.has(voter);
  }

  logEvent(event: string, id: number | null, sender: string, height: number): { ok: boolean; value?: number } {
    this.loggedEvents.push({ event, id: id ?? null, sender, height });
    return { ok: true };
  }

  stxGetBalance(account: string): number {
    return this.balances.get(account) ?? 0;
  }

  stxTransfer(amount: number, from: string, to: string): { ok: boolean; value?: number } {
    const fromBal = this.stxGetBalance(from);
    if (fromBal < amount) return { ok: false, value: ERR_INSUFFICIENT_FUNDS };
    this.balances.set(from, fromBal - amount);
    this.balances.set(to, (this.balances.get(to) ?? 0) + amount);
    return { ok: true };
  }

  registerProject(
    recipient: string,
    description: string,
    milestones: Milestone[],
    status: string
  ): { ok: boolean; value?: number } {
    const projectId = this.state.nextProjectId;
    if (this.caller !== this.state.admin) return { ok: false, value: ERR_NOT_AUTHORIZED };
    if (projectId >= this.state.maxProjects) return { ok: false, value: ERR_MAX_PROJECTS_EXCEEDED };
    if (recipient === "SP000000000000000000000000000000000000000") return { ok: false, value: ERR_INVALID_ADDRESS };
    if (description.length === 0 || description.length > 500) return { ok: false, value: ERR_INVALID_DESCRIPTION };

    this.state.projects.set(projectId, {
      recipient,
      description,
      totalAllocated: 0,
      totalReleased: 0,
      milestones,
      status,
      registrationTimestamp: this.blockHeight,
    });
    this.state.nextProjectId++;
    this.logEvent("project-registered", projectId, this.caller, this.blockHeight);
    return { ok: true, value: projectId };
  }

  proposeDistribution(projectId: number, amount: number) {
    const proposalId = this.state.nextProposalId;
    this.state.proposals.set(proposalId, {
      projectId,
      amount,
      proposer: this.caller,
      votesFor: 0,
      votesAgainst: 0,
      startBlock: this.blockHeight,
      endBlock: this.blockHeight + this.state.votingPeriod,
      executed: false,
    });
    this.state.nextProposalId++;
    this.logEvent("distribution-proposed", proposalId, this.caller, this.blockHeight);
    return { ok: true, value: proposalId };
  }

  voteOnProposal(proposalId: number, vote: boolean) {
    const proposal = this.state.proposals.get(proposalId)!;
    if (vote) proposal.votesFor++;
    else proposal.votesAgainst++;
    this.state.proposals.set(proposalId, proposal);
    this.logEvent("vote-cast", proposalId, this.caller, this.blockHeight);
    return { ok: true };
  }

  executeDistribution(proposalId: number) {
    const proposal = this.state.proposals.get(proposalId)!;
    const project = this.state.projects.get(proposal.projectId)!;
    this.stxTransfer(proposal.amount, this.caller, project.recipient);
    project.totalReleased += proposal.amount;
    this.state.projects.set(proposal.projectId, project);
    proposal.executed = true;
    this.state.proposals.set(proposalId, proposal);
    this.logEvent("distribution-executed", proposalId, this.caller, this.blockHeight);
    return { ok: true };
  }
}

describe("FundDistributor", () => {
  let contract: FundDistributorMock;

  beforeEach(() => {
    contract = new FundDistributorMock();
  });

  it("proposes a distribution", () => {
    contract.registerProject("ST1RECIPIENT", "desc", [], "active");
    const result = contract.proposeDistribution(1, 500);
    expect(result.ok).toBe(true);
    expect(result.value).toBe(1);
    const proposal = contract.state.proposals.get(1);
    expect(proposal?.amount).toBe(500);
    expect(contract.loggedEvents.at(-1)?.event).toBe("distribution-proposed"); // ✅ last event
  });

  it("votes on a proposal", () => {
    contract.registerProject("ST1RECIPIENT", "desc", [], "active");
    contract.proposeDistribution(1, 500);
    const result = contract.voteOnProposal(1, true);
    expect(result.ok).toBe(true);
    const proposal = contract.state.proposals.get(1);
    expect(proposal?.votesFor).toBe(1);
    expect(contract.loggedEvents.at(-1)?.event).toBe("vote-cast"); // ✅ last event
  });

  it("executes a distribution", () => {
    contract.registerProject("ST1RECIPIENT", "desc", [], "active");
    contract.proposeDistribution(1, 500);
    contract.voteOnProposal(1, true);
    contract.blockHeight += 145;
    const result = contract.executeDistribution(1);
    expect(result.ok).toBe(true);
    const project = contract.state.projects.get(1);
    expect(project?.totalReleased).toBe(500);
    expect(contract.loggedEvents.at(-1)?.event).toBe("distribution-executed"); // ✅ last event
  });
});
