shutdownOperator:
  turndown:
    # -- Enables the clusterturndown feature
    enabled: "false"
    # -- Scheduled time when cluster will be scaled down
    scaledownSchedule: "0 5 31 2 *"
    # -- Scheduled time when cluster will be scaled up
    scaleupSchedule: "0 5 31 2 *"