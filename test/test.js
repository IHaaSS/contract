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
    await i.addComment(incidents[0], bytes, bytes, [{'name': name, 'content': bytes}])
    let incident = await i.getIncident(incidents[0])
    assert.equal(incident[3].length, 1)
    let comment = await i.getComment(incident[3][0])
    assert.equal(comment[3], bytes)
    let attachmentName = await i.attachmentNames(bytes)
    assert.equal(attachmentName, name)
  })

  it("should get incident attachments", async() => {
    let incident = await i.getIncident(bytes)
    let attachment = await i.attachmentNames(incident[4][0])
    assert.equal(attachment, 'testattach')
    let attachments = await i.getAttachments(incident[4])
    assert.equal(attachments.length, 1)
  })

  it("should vote up on an incident", async() => {
    await i.voteIncident(bytes, true);
    let incident = await i.getIncident(bytes)
    assert.equal(incident[5].length, 1)
    assert.equal(incident[5][0], accounts[0])
  })

  it("should vote down on a comment", async() => {
    let ref = web3.utils.soliditySha3(bytes, bytes)
    await i.voteComment(ref, false)
    let comment = await i.getComment(ref)
    assert.equal(comment[6].length, 1)
    assert.equal(comment[6][0], accounts[0])
  })

  it("should remove an incident", async() => {
    await i.removeIncident(bytes, 0);
  })
});
