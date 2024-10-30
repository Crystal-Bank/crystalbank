# Initialize queue

def process_queue(queue : ES::Queue)
  event_bus = ES::Config.event_bus
  event_handlers = ES::Config.event_handlers
  store = ES::Config.event_store

  channel = queue.listen(polling_sleep: 100.milliseconds, batch_size: 100)

  loop do
    message = channel.receive

    es_event = store.fetch_event(message.header.event_id)
    h = ES::Event::Header.from_json(es_event.header.to_json)
    event = event_handlers.event_class(h.event_handle).new(h, es_event.body)

    if event_bus.publish(event)
      queue.archive(message.msg_id)
    end
  end
end

queue = ES::QueueAdapters::Postgres.new("default", DB.open(CrystalBank::Env.queue_uri))
queue.setup

# Start queue listener
spawn process_queue(queue)
