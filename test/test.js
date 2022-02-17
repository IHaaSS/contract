const bs58 = require('bs58')
const Incidents = artifacts.require("Incidents")


contract("Incidents", accounts => {
  let i;
  let ipfsHash = "Qmdb6QCW1AWCyjrtLc8WXwFPU8fAh1ZvrVkqduFiVFiEYS";
  let ipfsHash2 = "QmaE3KBxobwTjiotDauWYKrfuBXwXJJa9cvmfZikLk4H7L";
  const bytes = "0x" + bs58.decode(ipfsHash).toString('hex').slice(4)
  const bytes2 = "0x" + bs58.decode(ipfsHash2).toString('hex').slice(4)

  before(async () => {
    i = await Incidents.deployed();
  });

  it("should register users", async() => {
    await i.register(accounts[1]);
    await i.register(accounts[2]);
  });

  it("should add a new incident", async() => {
    await i.addIncident(bytes, [{'name': 'testattach', 'content': bytes}], {from: accounts[0]});
    let incidents = await i.getIncidents()
    assert.equal(incidents.length, 1)
    assert.equal(incidents[0], bytes)

    let incident = await i.incidents(incidents[0])
    assert.equal(incident.author, accounts[0])
  })

  it("should add a comment to an incident", async() => {
    let incidents = await i.getIncidents()
    let name = 'a'
    let receipt = await i.addComment(incidents[0], incidents[0], bytes, [{'name': name, 'content': bytes}], bytes2, 2)
    let incident = await i.getIncident(incidents[0])
    assert.equal(incident['comments'].length, 1)
    assert.equal(incident['comments'][0]['ref'], web3.utils.soliditySha3(incidents[0], 0))
    assert.equal(incident['comments'][0]['ref'], receipt['logs'][0]['args'][0])
    assert.equal(incident['comments'][0]['content'], bytes) // test comments
    assert.equal(incident['comments'][0]['attachments'][0]['name'], name)  // test attachments
  })

  it("should vote up on an incident", async() => {
    await i.voteIncident(bytes, 1);
    let incident = await i.getIncident(bytes)
    assert.equal(incident['votes'][0]['voter'], accounts[0])
  })

  it("should vote down on a comment", async() => {
    let ref = web3.utils.soliditySha3(bytes, 0)
    await i.voteComment(bytes, ref, -1)
    let comment = await i.getComment(ref)
    assert.equal(comment['votes'][0]['voter'], accounts[0])
  })

  it("should vote up on a status and incident update comment", async() => {
    let ref = web3.utils.soliditySha3(bytes, 0)
    let comment = await i.getComment(ref)
    let incident_update = comment['incident_update']
    await i.voteComment(bytes, ref, 1, {from: accounts[1]})
    await i.voteComment(bytes, ref, 1, {from: accounts[2]})
    comment = await i.getComment(ref)
    assert.equal(comment['incident_update'], 0)
    assert.equal(comment['status_update'], 0)
    let incidents = await i.getIncidents()
    let incident = await i.getIncident(incident_update)
    assert.equal(incidents[0], incident_update)
    assert.equal(incident['comments'].length, 1)
  })

  it("should remove an incident", async() => {
    await i.removeIncident(bytes, 0);
  })
});
