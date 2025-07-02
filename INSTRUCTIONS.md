## 8.1
- Follow the instructions from the lesson and use the spl-token-cli to create
    a) A fungible token with a supply of 10,000
    b) An NFT
- Try sending these tokens to others in your team , and use the command line to find details about the tokens.
- Try sending using both the transfer and transfer --fund-recipient approach.

## 8.2
- Modify the existing msg! in example1-helloworld to log the program ID.
- Retrieve the total program size of example1-helloworld.
- Retrieve the lamport balance of example2-counter.
- Modify the client for example2-counter to feed an incorrect address for the greeting account to the program.

## 9.1

Work through the CPI example : example4-cpi. You can run it with
`npm run build`
`npm run deploy:4`
`npm run call:4`
This program receives no instruction data, no accounts and it only logs a message using the msg! macro that can be viewed in the window running
`solana logs`

## 9.2 
Work through the compute budget example : example5-compute. You can run it with
`npm run build`
`npm run deploy:5`
`npm run call:5`

## 9.3
Work through the PDA example : example6-pda You can run it with
`npm run build`
`npm run deploy:6`
`npm run call:6`

## 9.4
Anchor : Create a basic program, follow the instructions here: 
https://examples.anchor-lang.com/docs/hello-world


# 10

Try a simple client transaction in Solana playground (https://beta.solpg.io/)

Make sure you are connected to the devnet and you have a wallet set up
Run the default client code, this will tell you your balance.
Create an airdrop signature and request the airdrop from the connection object pg.connection.requestAirdrop you will need to add your public key and the number of lamports you want.
Use await pg.connection.confirmTransaction; to confirm the transaction.
Investigating Dapp Scaffold

You need to install a wallet plugin in your browser, such as phantom
Follow the installation instructions in the notes.

Try following the functionality it provides

Make sure your wallet is connected to the dev network
Try the airdrop to give yourself some SOL
Try to sign a message
Try altering the code to send a transaction to send to a hardcoded address You can create a public key from a String, such as 5xot9PVkphiX2adznghwrAuxGs2zeWisNSxMW6hU6Hkj See https://docs.solana.com/developing/clients/javascript-reference#publickey

Look for the transactions on the devnet blockchain explorer.

Extra Credit
recommended reading

How NFTs are Represented on Solana
Why Governance is the Greatest Problem for Blockchains to Solve

# 11

Use the Anchor command line tools to create a new project.
Adapt the default program as follows
In an account we want to store a balance of type u64
On initialisation, this balance should be set to 100
Write a test to check that the balance was initialised correctly.
Lottery Program
From the Bootcamp repo, anchor examples

Modify the lottery program so that the payout is only 90% of the total deposits.
Add a function that allows lottery admin to withdraw funds after the winner is picked.

# 12 
Further develop the anchor program you started in the last homework

Add a function to allow the balance to be updated in steps of 100 up to a maximum of 1000.
If you try to update the balance when it is at its maximum value, throw a custom error with an appropriate error message.
What constraints should your program have ?

# 13

Discuss in your teams
Should projects spend more on security ?
What measures would you take to improve security ?
Should bounties be paid to attackers after the exploit ?
Look through the example code in the repo, can you find any potential issues ? Think particularly about the flow of the lottery game.
Install the Neodyme workshop and watch the video explaining the first vulnerability
https://workshop.neodyme.io/index.html

# 14

Work through the Tiny Adventure tutorial from the Solana Cookbook.
https://solanacookbook.com/gaming/hello-world.html#getting-started-with-your-first-solana-game

# 15

For the Rock Paper Scissors example in the repo

Add additional hands using this relationship diagram
  
How do you handle the situation where one player refuses to provide the hand?