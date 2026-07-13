import { Card, Col, Row } from "antd";
import "./index.scss";
import Notice from "./components/Notice";

const HomePage = () => {
  return (
    <Row className="main" gutter={8}>
      <Col className="clo-left" flex="none" span={6}>
        <Card bordered={false}></Card>
      </Col>
      <Col className="clo-center" flex="auto">
        <Notice title="公告" content="公告内容" />
      </Col>
      <Col className="clo-right" flex="none" span={6}>
        <Card bordered={false}></Card>
      </Col>
    </Row>
  );
};

export default HomePage;
