import { Card } from "antd";

type NoticeProps = {
  content: string;
  title?: string;
};

const Notice = (props: NoticeProps) => {
  return (
    <Card
      title={props.title ? props.title : "公告"}
      size="small"
      bordered={false}
    >
      <p>{props.content}</p>
    </Card>
  );
};

export default Notice;
