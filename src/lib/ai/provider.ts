import { messageClassificationSchema,type MessageClassification } from "@/lib/domain/contracts";
export type AnalyzeMessageInput={subject:string;bodyText:string;sender:string};
export interface AiProvider{analyzeMessage(input:AnalyzeMessageInput):Promise<MessageClassification>}
export async function analyzeWith(provider:AiProvider,input:AnalyzeMessageInput){return messageClassificationSchema.parse(await provider.analyzeMessage(input));}
