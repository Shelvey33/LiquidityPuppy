from brownie import accounts, USDC, Reserve, SheqelToken, Distributor, Contract

# Setting swap adresse + deployment of USDC
spookyswapAddress = "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff" # polygon testnet
acct = accounts.load('shqdeployer')
usdc = USDC.deploy(100_000_000 * 10 ** 6, {'from': acct}, publish_source=True) 

reserve_contract = Reserve.deploy(
    spookyswapAddress,
    usdc.address,
{'from': acct},publish_source=True
)
sheqeltoken = SheqelToken.deploy(
reserve_contract.address,   
acct,
800 * 10**6 * 10**18,
spookyswapAddress,
usdc.address,
{'from': acct},publish_source=True
)

distributor = Distributor.deploy(
        usdc.address,
        reserve_contract.address,
        {'from': acct},publish_source=True
    )

usdc_amount = 10_000 * 10 ** 6
usdc_amount_liq = 1 * 10**6
shq_amount_liq = 2000 * 10 ** 18
shq_amount = 5 * 10**6 * 10 ** 18

distributor.setShq(sheqeltoken.address)
sheqeltoken.setDistributor(distributor.address)
reserve_contract.setSheqelTokenAddress(sheqeltoken.address, {'from' : acct})

# Setting base usdc amount to reserve
usdc.transfer(reserve_contract.address, 999 * 10**6, {'from' : acct})

# Setting up liquidity
# Adding liquidity to the pool
uniswapRouter = Contract.from_explorer(spookyswapAddress)
# Approving the transaction
sheqeltoken.approve(spookyswapAddress, shq_amount, {"from": acct})
usdc.approve(spookyswapAddress, shq_amount, {"from": acct})

# Buying the adequate liquidity
usdc.approve(reserve_contract, 1 * 10**6, {"from": acct})



uniswapRouter.addLiquidity(
    sheqeltoken.address,
    usdc.address,
    shq_amount_liq,
    1*10**6,
    0,
    0,
    acct,
    1712933164 # Should be block.timestamp,
    , {"from": acct}

)

# Sending 9k USDC to shelvey metamask and 3.5k to FP
usdc.transfer("0x912858f594596B93abD9bBbA663E24aF53FaDE7d", 9000 * 10**6, {'from' : acct}) # shelvey
usdc.transfer("0x58Dbcfa99EaDAA55eC8139C4Bd53A36D748bB436", 3500 * 10**6, {'from' : acct}) # FP

# Sending half of the 197998 SHQ to shelvey and half to FP
sheqeltoken.transfer("0x912858f594596B93abD9bBbA663E24aF53FaDE7d", (197998/2 -1) * 10**18, {'from' : acct}) # shelvey
sheqeltoken.transfer("0x58Dbcfa99EaDAA55eC8139C4Bd53A36D748bB436", (197998/2 -1) * 10**18, {'from' : acct}) # FP


print("Sheqel Token Address : " + sheqeltoken.address)
print("Reserve Address : " + reserve_contract.address)
print("Distributor Address : " + distributor.address)
print("USDC Address : " + usdc.address)
print("DeX Address : " + spookyswapAddress)  


