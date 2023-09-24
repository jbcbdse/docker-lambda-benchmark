import { Context } from "aws-lambda";
import { setTimeout } from "timers/promises";
export async function handler(event: unknown, context: Context): Promise<void> {
  await setTimeout(5000)
  console.log(JSON.stringify(event));
}