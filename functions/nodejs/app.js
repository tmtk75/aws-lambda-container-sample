const { unzip, gzip, gunzip } = require("zlib");
const { promisify } = require("util");

//
const do_unzip = promisify(unzip);
const do_gzip = promisify(gzip);

//
exports.handler = async function (event, context, callback) {
  console.log("EVENT: " + JSON.stringify(event));
  return context.logStreamName;
};

/*
 * https://aws.amazon.com/blogs/compute/amazon-kinesis-firehose-data-transformation-with-aws-lambda/
 */
exports.process = async function (event, context) {
  const records = event.records.map(async (r) => {
    const b64data = r.data;
    const rawdata = Buffer.from(b64data, "base64");
    const plaindata = await do_unzip(rawdata);
    const json = JSON.parse(plaindata.toString());

    const newdata = JSON.stringify({
      ...json,
      message: "yeah, processed successfully. this message was added by the processor.",
    });
    const data = Buffer.from(await do_gzip(newdata)).toString("base64");

    console.info(`event:`, event, `context:`, context);
    return {
      recordId: r.recordId,
      data,
      result: "Ok",
    };
  });
  return {
    records: await Promise.all(records),
  };
};

exports.subscribe = async function (input, context) {
  // const payload = Buffer.from(input.awslogs.data, "base64");
  // console.log(`payload:`, payload)
  // gunzip(payload, function (e, result) {
  //   if (e) {
  //     context.fail(e);
  //   } else {
  //     result = JSON.parse(result.toString("ascii"));
  //     console.log("Event Data:", JSON.stringify(result, null, 2));
  //     context.succeed();
  //   }
  // });
  // console.log(`input.awslogs.data:`, input.awslogs.data);
  const b64data = input.awslogs.data;
  const rawdata = Buffer.from(b64data, "base64");
  const plaindata = await do_unzip(rawdata);
  // const json = JSON.parse(plaindata.toString());
  console.info("received log events:", plaindata.toString());
};
