import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { HelloWorld } from "../../hello-world/target/types/hello_world";

describe("init", () => {
  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.AnchorProvider.env());

  const program = anchor.workspace.helloWorld as Program<HelloWorld>;

  it("Is initialized!", async () => {
    // Add your test here.
    const tx = await program.methods.initialize().rpc();
    console.log("Your transaction signature", tx);
  });
});


// describe("hello-world", () => {
//   anchor.setProvider(anchor.AnchorProvider.env());
//   const program = anchor.workspace.HelloWorld as Program<HelloWorld>;


//   it("Mic testing - Hello world", async () => {
//     const tx = await program.methods.helloWorld().rpc();
//     console.log("Your transaction signature", tx);
//   });
// });