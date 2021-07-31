// loadScript("D:\\projects\\src\\github.com\\ethereum\\go-ethereum\\solidity\\test\\client.js")
var baseAddr = eth.accounts[0];
var basePwd = "123";
var initGasPrice = 5e10;

web3.personal.unlockAccount(baseAddr, basePwd, 0);


function sleep(delay) {
	var start = (new Date()).getTime();
	while ((new Date()).getTime() - start < delay) {
		continue;
	}
}

function sendTx(src, tgtaddr, amount, strData) {	
	//initGasPrice--;
	web3.eth.sendTransaction({
			from: src,
			value: web3.toWei(amount, 'ether'),
			to: tgtaddr,
			gas: "5000000",
			//gasPrice: initGasPrice.toString(),//web3.eth.gasPrice,
			data: strData
		},
		function (e, hash){
		    console.log(e, hash);
		}
	);
	//console.log('sending from:' + 	src + ' to:' + tgtaddr  + ' with data:' + strData);
}

function waitTxPoolEmpty() {
	while (JSON.stringify(txpool.inspect.pending) != "{}") {
		sleep(1000);
	}
	
	console.log("txpool is empty...");
}

function unlockAccounts( start, end) {
	for (var i = start; i <= end; i++) {
		web3.personal.unlockAccount(eth.accounts[i], basePwd, 0);
	}
}

// CrossChain start
// setAcceptToken(bep20token.address, true)
// crosschain.acceptToken.call(bep20token.address)
function setAcceptToken(token, isAccepted) {
    sendTx(baseAddr, crosschain.address, 0, crosschain.setAcceptToken.getData(token, isAccepted));
}
// setAcceptChain(0, true)
// crosschain.acceptChain.call(0)
function setAcceptChain(chain, isAccepted) {
    sendTx(baseAddr, crosschain.address, 0, crosschain.setAcceptChain.getData(chain, isAccepted));
}
// setMaxAmount(bep20token.address, 1e29)
function setMaxAmount(token, amount) {
    sendTx(baseAddr, crosschain.address, 0, crosschain.setMaxAmount.getData(token, amount));
}
// setMaxAmountPerDay(bep20token.address, 1e29)
function setMaxAmountPerDay(token, amount) {
    sendTx(baseAddr, crosschain.address, 0, crosschain.setMaxAmountPerDay.getData(token, amount));
}
// approve(crosschain.address, -1)
// bep20token.allowance.call(eth.accounts[0], crosschain.address)
function approve(to, amount) {
	sendTx(baseAddr, bep20token.address, 0, bep20token.approve.getData(to, amount));
}
// crossChainTransfer(bep20token.address,1e18,eth.accounts[1], 0)
function crossChainTransfer(token, amount, to, chain) {
    sendTx(baseAddr, crosschain.address, 0, crosschain.crossChainTransfer.getData(token, amount, to, chain));
}
function getSendPool(start, end) {
}
// CrossChain end
