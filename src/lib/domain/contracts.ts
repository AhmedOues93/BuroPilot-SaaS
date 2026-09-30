import { z } from "zod";
export const executionModeSchema = z.enum(["AUTO","APPROVAL_REQUIRED","MANUAL"]);
export type ExecutionMode = z.infer<typeof executionModeSchema>;
export const messageClassificationSchema = z.object({intent:z.enum(["NEW_INQUIRY","REPLY","COMPLAINT","OTHER"]),urgency:z.enum(["LOW","NORMAL","HIGH"]),summary:z.string().min(1).max(1200),companyName:z.string().trim().min(1).max(200).nullable(),contactName:z.string().trim().min(1).max(200).nullable(),phone:z.string().trim().max(80).nullable(),location:z.string().trim().max(300).nullable(),requestedService:z.string().trim().max(500).nullable(),quantities:z.array(z.object({label:z.string().max(100),value:z.string().max(200)})).max(20),requestedPeriod:z.string().trim().max(300).nullable(),missingInformation:z.array(z.string().min(1).max(300)).max(20),confidence:z.number().min(0).max(1)});
export type MessageClassification=z.infer<typeof messageClassificationSchema>;
export const proposedActionSchema=z.object({type:z.enum(["CREATE_CASE","DRAFT_REPLY","SEND_REPLY","CREATE_TASK","SCHEDULE_FOLLOW_UP","CANCEL_FOLLOW_UP"]),reasonCode:z.string().regex(/^[A-Z0-9_]{2,80}$/),reasonSummary:z.string().min(1).max(500),payload:z.record(z.string(),z.unknown())});
export type ProposedAction=z.infer<typeof proposedActionSchema>;
