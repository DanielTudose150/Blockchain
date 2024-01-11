# Testing

1. An account deploys ***SampleToken*** with X totalSupply tokens.
2. An account deploys ***SampleTokenSale*** with the previous ***SampleToken*** address and a starting cost of a token.
3. An account that posses tokens approves ***SampleTokenSale*** to sell some of the their tokens.
4. An account B buys tokens with ETH.
5. An account C deploys the ***ProductIdentification*** contract.
5. C sets the sampleCoinAddress with the address of the ***SampleToken*** contract.
6. C sets the registration tax.
7. B approves ***ProductIdentification*** to handle some of their tokens.
8. B registers as a producer by paying the registration tax.
1. B registers a product by providing a name and a volume. In this case, it would be the name of a car.
1. B deploys the ***MyAuction*** contract by providing the bidding time in hours, their address, the name of the car, a registration number, the address of the ***ProductIdentification*** contract and the address of the ***SampleToken*** contract.
1. An account bids by paying an amount of tokens.
    1. To be able to bid, they need to provide an amount of tokens strictly higher than the current highest bid.
    1. They cannot bid again.
1. B cancels the auction.
    1. The users that lost the bid can withdraw their tokens.
1. B destroys the auction.
    1. If there were users that have lost the auction and have not withdrawn their tokens until this moment, their bids will be refunded.
    