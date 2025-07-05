use anchor_lang::prelude::*;

declare_id!("46NNnymqhjHDyjiyyoMEKutTmZs9c1E5Yv53wSLV8ZFT");

#[program]
pub mod onchain_voting {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}
