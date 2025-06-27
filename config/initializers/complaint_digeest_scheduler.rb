return unless defined?(Rails::Server)

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton

# Run daily at 9:00 AM server time
scheduler.cron '0 9 * * *' do
  Rails.logger.info "[Scheduler] Running daily complaint digest"
  ComplaintDigestService.send_daily_pending_summary
rescue => e
  Rails.logger.error "[Scheduler] Failed to send complaint digest: #{e.message}"
end
