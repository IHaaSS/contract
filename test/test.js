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
    await i.addIncident(bytes, {from: accounts[0]});
    let incidents = await i.getIncidents()
    assert.equal(incidents.length, 1)
    assert.equal(incidents[0], bytes)

    let incident = await i.incidents(incidents[0])
    assert.equal(incident.author, accounts[0])
  })

  it("should add a comment to an incident", async() => {
    let incidents = await i.getIncidents()
    await i.addComment(incidents[0], bytes, [{'name': 'a', 'content': bytes}])
    let incident = await i.incidents(incidents[0])
    assert.equal(incident.attachments, 1)
  })
});
