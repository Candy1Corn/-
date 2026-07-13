import { request } from "../utils";

function getNotice() {
  request({
    url: "/content/notice",
    method: "get",
  });
}
