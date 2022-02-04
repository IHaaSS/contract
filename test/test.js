const bs58 = require('bs58')
const Incidents = artifacts.require("Incidents")


contract("Incidents", accounts => {
  let i;
  let ipfsHash = "Qmdb6QCW1AWCyjrtLc8WXwFPU8fAh1ZvrVkqduFiVFiEYS";
  const bytes = "0x" + bs58.decode(ipfsHash).toString('hex').slice(4)

  before(async () => {
    i = await Incidents.deployed();
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
    let receipt = await i.addComment(incidents[0], incidents[0], bytes, [{'name': name, 'content': bytes}])
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
    assert.equal(incident['votes'].length, 1)
    assert.equal(incident['votes'][0]['voter'], accounts[0])
  })

  it("should vote down on a comment", async() => {
    let ref = web3.utils.soliditySha3(bytes, 0)
    await i.voteComment(ref, -1)
    let comment = await i.getComment(ref)
    assert.equal(comment['votes'].length, 1)
    assert.equal(comment['votes'][0]['voter'], accounts[0])
  })

  it("should remove an incident", async() => {
    await i.removeIncident(bytes, 0);
  })
});
